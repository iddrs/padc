//! # PADC GUI
//!
//! Interface gráfica (Iced/Rust) para o PADC — conversor de dados dos
//! `*.txt` do SIAPC/PAD para DuckDB.
//!
//! A interface executa o comando `php padc.php <source_dir> <target_file>`
//! e exibe a saída bruta (stdout + stderr) do script em uma área com
//! barra de rolagem, em tempo real.

#![cfg_attr(windows, windows_subsystem = "windows")]

use std::path::{Path, PathBuf};
use std::process::Stdio;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Duration;

use iced::futures::channel::mpsc;
use tokio::io::AsyncBufReadExt;
use iced::widget::scrollable::RelativeOffset;
use iced::widget::{
    button, column, container, row, scrollable, text, text_input, Id, Space,
};
use iced::{window, Alignment, Background, Color, Element, Font, Length, Padding, Task, Theme};
use serde::{Deserialize, Serialize};

/// Título do programa, exibido na janela e no cabeçalho.
const APP_TITLE: &str = "PADC — Conversor de dados dos *.txt do SIAPC/PAD para DuckDB";

/// Subtítulo exibido no cabeçalho.
const APP_SUBTITLE: &str = "Executa o comando: php padc.php <diretório dos *.txt> <arquivo DuckDB>";

/// Informações do desenvolvedor, exibidas na barra de status.
const DEVELOPER: &str = "Desenvolvido por Everton da Rosa <everton3x@gmail.com>";

/// Nome do arquivo de configuração (compartilhado com a GUI em Python).
const CONFIG_FILE: &str = "padc_gui_config.json";

/// Cor de fundo do cabeçalho.
const HEADER_BG: Color = Color::from_rgb(0.09, 0.20, 0.38);

/// Cor de fundo da barra de status.
const STATUS_BG: Color = Color::from_rgb(0.90, 0.92, 0.95);

/// Intervalo usado apenas para monitorar o pedido de parada da execução.
const STOP_POLL_INTERVAL: Duration = Duration::from_millis(250);

/// Flag `CREATE_NO_WINDOW` do Windows: evita abrir um console vazio
/// ao executar o script PHP a partir da interface gráfica.
#[cfg(windows)]
const CREATE_NO_WINDOW: u32 = 0x0800_0000;

// ---------------------------------------------------------------------------
// Mensagens
// ---------------------------------------------------------------------------

/// Eventos tratados pela interface.
#[derive(Debug, Clone)]
enum Message {
    /// O usuário digitou um novo valor no campo "Arquivos do PAD".
    SourceChanged(String),
    /// O usuário digitou um novo valor no campo "Arquivo DuckDB".
    TargetChanged(String),
    /// O usuário pediu para escolher o diretório de origem.
    BrowseSource,
    /// O usuário pediu para escolher o arquivo de destino.
    BrowseTarget,
    /// Resultado do diálogo de seleção de diretório.
    SourcePicked(Option<String>),
    /// Resultado do diálogo de seleção do arquivo DuckDB.
    TargetPicked(Option<String>),
    /// O usuário pressionou "Executar".
    Run,
    /// O usuário pressionou "Parar".
    Stop,
    /// O usuário pressionou "Limpar saída".
    ClearOutput,
    /// Uma linha lida da saída (stdout ou stderr) do script.
    OutputLine(String),
    /// O processo terminou. `None` quando não há código de saída.
    Finished(Option<i32>),
    /// Falha ao iniciar ou acompanhar o processo.
    ProcessError(String),
    /// O executor da execução terminou (todos os eventos já foram enviados).
    RunnerDone,
    /// A caixa de mensagem de conclusão foi fechada.
    NoticeClosed,
}

// ---------------------------------------------------------------------------
// Configuração
// ---------------------------------------------------------------------------

/// Parâmetros persistidos entre sessões, no mesmo formato usado pela GUI
/// em Python (`padc_gui_config.json`).
#[derive(Debug, Clone, Serialize, Deserialize)]
struct Config {
    #[serde(default = "default_php_executable")]
    php_executable: String,
    #[serde(default)]
    source_dir: String,
    #[serde(default)]
    target_file: String,
}

fn default_php_executable() -> String {
    "php".to_string()
}

impl Default for Config {
    fn default() -> Self {
        Self {
            php_executable: default_php_executable(),
            source_dir: String::new(),
            target_file: String::new(),
        }
    }
}

// ---------------------------------------------------------------------------
// Localização do projeto
// ---------------------------------------------------------------------------

/// Procura o `padc.php` ao lado do executável (ou do diretório atual)
/// e devolve o caminho absoluto do script, se encontrado.
fn locate_script() -> Option<PathBuf> {
    let mut candidates: Vec<PathBuf> = Vec::new();

    if let Ok(executable) = std::env::current_exe() {
        if let Some(directory) = executable.parent() {
            candidates.push(directory.to_path_buf());
            candidates.push(directory.join(".."));
        }
    }

    if let Ok(current_dir) = std::env::current_dir() {
        candidates.push(current_dir);
    }

    candidates.push(PathBuf::from(env!("CARGO_MANIFEST_DIR")).join(".."));

    for directory in candidates {
        let script = directory.join("padc.php");
        if !script.is_file() {
            continue;
        }

        let script = if script.is_absolute() {
            script
        } else {
            std::env::current_dir().ok()?.join(script)
        };

        return Some(script);
    }

    None
}

// ---------------------------------------------------------------------------
// Aplicação
// ---------------------------------------------------------------------------

/// Estado da interface.
struct App {
    /// Executável PHP usado para rodar o script.
    php_executable: String,
    /// Argumento `source_dir`: diretório com os `*.txt` do PAD.
    source_dir: String,
    /// Argumento `target_file`: caminho do arquivo DuckDB de destino.
    target_file: String,
    /// Diretório do projeto (onde fica o `padc.php`).
    project_root: PathBuf,
    /// Caminho do script `padc.php`, quando localizado.
    script: Option<PathBuf>,
    /// Texto bruto acumulado da saída do conversor.
    output: String,
    /// Indica que um processo está em execução.
    running: bool,
    /// Sinal compartilhado com o processo para pedir a parada.
    stop: Option<Arc<AtomicBool>>,
    /// Texto exibido na barra de status.
    status: String,
    /// Identificador da área de rolagem da saída.
    scroll_id: Id,
}

impl Default for App {
    fn default() -> Self {
        let script = locate_script();
        let project_root = script
            .as_deref()
            .and_then(Path::parent)
            .map(Path::to_path_buf)
            .unwrap_or_else(|| {
                std::env::current_dir().unwrap_or_else(|_| PathBuf::from("."))
            });

        let config = load_config(&project_root);

        let status = if script.is_some() {
            "Pronto.".to_string()
        } else {
            "Aviso: script padc.php não encontrado. Coloque o executável ao lado do projeto."
                .to_string()
        };

        Self {
            php_executable: config.php_executable,
            source_dir: config.source_dir,
            target_file: config.target_file,
            project_root,
            script,
            output: String::new(),
            running: false,
            stop: None,
            status,
            scroll_id: Id::new("padc-output"),
        }
    }
}

fn load_config(project_root: &Path) -> Config {
    std::fs::read_to_string(project_root.join(CONFIG_FILE))
        .ok()
        .and_then(|raw| serde_json::from_str(&raw).ok())
        .unwrap_or_default()
}

impl App {
    fn new() -> Self {
        Self::default()
    }

    // -- Atualização ---------------------------------------------------------

    fn update(&mut self, message: Message) -> Task<Message> {
        match message {
            Message::SourceChanged(value) => {
                self.source_dir = value;
                self.save_config();
                Task::none()
            }
            Message::TargetChanged(value) => {
                self.target_file = value;
                self.save_config();
                Task::none()
            }
            Message::BrowseSource => {
                let dialog =
                    rfd::AsyncFileDialog::new().set_title("Selecione o diretório com os *.txt do PAD");
                let dialog = if Path::new(&self.source_dir).is_dir() {
                    dialog.set_directory(&self.source_dir)
                } else {
                    dialog
                };

                Task::perform(
                    async move {
                        dialog
                            .pick_folder()
                            .await
                            .map(|handle| handle.path().display().to_string())
                    },
                    Message::SourcePicked,
                )
            }
            Message::BrowseTarget => {
                let dialog = rfd::AsyncFileDialog::new()
                    .set_title("Selecione o arquivo DuckDB de destino")
                    .set_file_name("padc.duckdb")
                    .add_filter("Arquivo DuckDB", &["duckdb"]);

                // A conversão pode criar o arquivo, então o diretório inicial
                // é apenas uma sugestão.
                let dialog = {
                    let suggested = Path::new(&self.target_file);
                    let directory = match suggested.parent() {
                        Some(parent) if !parent.as_os_str().is_empty() && parent.is_dir() => {
                            Some(parent.to_path_buf())
                        }
                        _ => Some(self.project_root.clone()),
                    };

                    match directory {
                        Some(directory) => dialog.set_directory(directory),
                        None => dialog,
                    }
                };

                Task::perform(
                    async move {
                        dialog
                            .save_file()
                            .await
                            .map(|handle| handle.path().display().to_string())
                    },
                    Message::TargetPicked,
                )
            }
            Message::SourcePicked(Some(path)) => {
                self.source_dir = path;
                self.save_config();
                Task::none()
            }
            Message::TargetPicked(Some(path)) => {
                self.target_file = path;
                self.save_config();
                Task::none()
            }
            Message::SourcePicked(None) | Message::TargetPicked(None) => Task::none(),
            Message::Run => self.run(),
            Message::Stop => {
                if let Some(stop) = &self.stop {
                    stop.store(true, Ordering::Relaxed);
                    self.status = "Parando...".to_string();
                }
                Task::none()
            }
            Message::ClearOutput => {
                self.output.clear();
                if !self.running {
                    self.status = "Pronto.".to_string();
                }
                Task::none()
            }
            Message::OutputLine(line) => {
                self.output.push_str(&line);
                self.output.push('\n');
                scroll_to_end(self.scroll_id.clone())
            }
            Message::Finished(code) => {
                self.running = false;
                self.stop = None;

                let status = match code {
                    Some(0) => "Processo concluído com sucesso.".to_string(),
                    Some(code) => format!("Processo encerrado com o código de saída {code}."),
                    None => "Processo finalizado sem código de saída.".to_string(),
                };

                self.status = status.clone();
                self.output.push('\n');
                self.output.push_str(&status);
                self.output.push('\n');

                let dialog =
                    Task::perform(show_completion_dialog(status), |_| Message::NoticeClosed);

                Task::batch([scroll_to_end(self.scroll_id.clone()), dialog])
            }
            Message::ProcessError(message) => {
                self.status = "Erro durante a execução.".to_string();
                self.output.push_str(&message);
                self.output.push('\n');
                scroll_to_end(self.scroll_id.clone())
            }
            Message::RunnerDone | Message::NoticeClosed => Task::none(),
        }
    }

    /// Valida os parâmetros e inicia o processo `php padc.php`.
    fn run(&mut self) -> Task<Message> {
        if self.running {
            return Task::none();
        }

        let Some(script) = self.script.clone() else {
            self.report_error(
                "Não encontrei o script `padc.php`. Copie o executável para o diretório do projeto e tente novamente.",
            );
            return Task::none();
        };

        let source_dir = self.source_dir.trim().to_string();
        let target_file = self.target_file.trim().to_string();

        if self.php_executable.trim().is_empty() {
            self.report_error("Informe o executável PHP.");
            return Task::none();
        }

        if source_dir.is_empty() {
            self.report_error("Selecione o diretório com os arquivos do PAD (\"Arquivos do PAD\").");
            return Task::none();
        }

        if !Path::new(&source_dir).is_dir() {
            self.report_error(&format!("O diretório de origem não existe:\n{source_dir}"));
            return Task::none();
        }

        if target_file.is_empty() {
            self.report_error("Informe o arquivo DuckDB de destino (\"Arquivo DuckDB\").");
            return Task::none();
        }

        if let Some(parent) = Path::new(&target_file).parent() {
            if !parent.as_os_str().is_empty() && !parent.is_dir() {
                self.report_error(&format!(
                    "O diretório do arquivo de destino não existe:\n{}",
                    parent.display()
                ));
                return Task::none();
            }
        }

        self.save_config();
        self.output.clear();
        self.output.push_str(&format!(
            "$ {} {} \"{}\" \"{}\"\n\n",
            self.php_executable,
            script.display(),
            source_dir,
            target_file
        ));
        self.running = true;
        self.status = "Executando...".to_string();

        let stop = Arc::new(AtomicBool::new(false));
        self.stop = Some(Arc::clone(&stop));

        let (sender, receiver) = mpsc::unbounded();

        let runner = Task::perform(
            run_php_process(
                self.php_executable.clone(),
                script,
                source_dir,
                target_file,
                self.project_root.clone(),
                stop,
                sender,
            ),
            |_| Message::RunnerDone,
        );

        Task::batch([Task::stream(receiver), runner])
    }

    fn report_error(&mut self, message: &str) {
        self.status = "Parâmetros inválidos.".to_string();
        self.output.push_str(message);
        self.output.push('\n');
    }

    fn save_config(&self) {
        let config = Config {
            php_executable: self.php_executable.clone(),
            source_dir: self.source_dir.clone(),
            target_file: self.target_file.clone(),
        };

        let Ok(json) = serde_json::to_string_pretty(&config) else {
            return;
        };

        let _ = std::fs::write(self.project_root.join(CONFIG_FILE), json);
    }

    // -- Visão ---------------------------------------------------------------

    fn view(&self) -> Element<'_, Message> {
        let header = container(
            column(vec![
                text(APP_TITLE).size(21).into(),
                text(APP_SUBTITLE).size(13).into(),
            ])
            .spacing(4),
        )
        .width(Length::Fill)
        .padding(Padding::from([14.0, 20.0]))
        .style(|_theme: &Theme| container::Style {
            background: Some(Background::Color(HEADER_BG)),
            text_color: Some(Color::WHITE),
            ..container::Style::default()
        });

        let source_field = row(vec![
            text("Arquivos do PAD").width(150).into(),
            text_input("Diretório com os arquivos *.txt do PAD", self.source_dir.as_str())
                .on_input(Message::SourceChanged)
                .on_submit(Message::Run)
                .padding(8)
                .width(Length::Fill)
                .into(),
            button("Procurar...")
                .on_press(Message::BrowseSource)
                .into(),
        ])
        .spacing(8)
        .align_y(Alignment::Center);

        let target_field = row(vec![
            text("Arquivo DuckDB").width(150).into(),
            text_input(
                "Caminho do arquivo DuckDB (será criado se não existir)",
                self.target_file.as_str(),
            )
            .on_input(Message::TargetChanged)
            .on_submit(Message::Run)
            .padding(8)
            .width(Length::Fill)
            .into(),
            button("Procurar...")
                .on_press(Message::BrowseTarget)
                .into(),
        ])
        .spacing(8)
        .align_y(Alignment::Center);

        let stop_button: Element<Message> = if self.running {
            button("Parar").on_press(Message::Stop).style(button::danger).into()
        } else {
            button("Parar").style(button::danger).into()
        };

        let run_button: Element<Message> = if self.running {
            button("Executar").style(button::primary).into()
        } else {
            button("Executar")
                .on_press(Message::Run)
                .style(button::primary)
                .into()
        };

        let controls = row(vec![
            Space::new().width(Length::Fill).into(),
            button("Limpar saída")
                .on_press(Message::ClearOutput)
                .style(button::secondary)
                .into(),
            stop_button,
            run_button,
        ])
        .spacing(8)
        .align_y(Alignment::Center);

        let output_content: Element<Message> = if self.output.is_empty() {
            text("A saída do conversor será exibida aqui.")
                .style(|_theme: &Theme| text::Style {
                    color: Some(Color::from_rgb(0.62, 0.64, 0.68)),
                    ..text::Style::default()
                })
                .into()
        } else {
            text(self.output.as_str())
                .font(Font::MONOSPACE)
                .size(13)
                .into()
        };

        let output_area = scrollable(
            container(output_content)
                .width(Length::Fill)
                .padding(10)
                .style(|_theme: &Theme| container::Style {
                    background: Some(Background::Color(Color::from_rgb(0.12, 0.13, 0.16))),
                    text_color: Some(Color::from_rgb(0.90, 0.92, 0.95)),
                    ..container::Style::default()
                }),
        )
        .id(self.scroll_id.clone())
        .direction(scrollable::Direction::Vertical(
            scrollable::Scrollbar::new(),
        ))
        .height(Length::Fill);

        let body = container(
            column(vec![
                source_field.into(),
                target_field.into(),
                controls.into(),
                text("Saída do conversor").size(14).into(),
                output_area.into(),
            ])
            .spacing(12),
        )
        .width(Length::Fill)
        .height(Length::Fill)
        .padding(Padding::from([16.0, 20.0]));

        let status_bar = container(
            row(vec![
                text(DEVELOPER).size(12).into(),
                Space::new().width(Length::Fill).into(),
                text(self.status.as_str()).size(12).into(),
            ])
            .align_y(Alignment::Center),
        )
        .width(Length::Fill)
        .padding(Padding::from([8.0, 12.0]))
        .style(|_theme: &Theme| container::Style {
            background: Some(Background::Color(STATUS_BG)),
            text_color: Some(Color::from_rgb(0.20, 0.20, 0.25)),
            ..container::Style::default()
        });

        column(vec![header.into(), body.into(), status_bar.into()]).into()
    }
}

// ---------------------------------------------------------------------------
// Execução do script
// ---------------------------------------------------------------------------

/// Rola a área de saída até o final.
fn scroll_to_end(scroll_id: Id) -> Task<Message> {
    iced::widget::operation::snap_to(
        scroll_id,
        RelativeOffset {
            x: Some(0.0),
            y: Some(1.0),
        },
    )
}

/// Exibe uma caixa de mensagem nativa informando a conclusão do processo.
async fn show_completion_dialog(status: String) {
    rfd::AsyncMessageDialog::new()
        .set_level(rfd::MessageLevel::Info)
        .set_title("PADC — Conclusão")
        .set_description(status)
        .set_buttons(rfd::MessageButtons::Ok)
        .show()
        .await;
}

/// Decodifica uma linha crua lida da saída do processo.
fn decode_line(bytes: &[u8]) -> String {
    let mut line = String::from_utf8_lossy(bytes).into_owned();
    if line.ends_with('\r') {
        line.pop();
    }
    line
}

/// Executa `php padc.php <source_dir> <target_file>` em segundo plano,
/// encaminhando cada linha da saída (stdout e stderr) para a interface.
async fn run_php_process(
    php: String,
    script: PathBuf,
    source_dir: String,
    target_file: String,
    working_dir: PathBuf,
    stop: Arc<AtomicBool>,
    sender: mpsc::UnboundedSender<Message>,
) {
    let mut command = tokio::process::Command::new(php.trim());
    command
        .arg(&script)
        .arg(&source_dir)
        .arg(&target_file)
        .current_dir(&working_dir)
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .kill_on_drop(true);

    #[cfg(windows)]
    command.creation_flags(CREATE_NO_WINDOW);

    let mut child = match command.spawn() {
        Ok(child) => child,
        Err(error) => {
            let _ = sender.unbounded_send(Message::ProcessError(format!(
                "Não foi possível executar o comando:\n\n{} {} \"{}\" \"{}\"\n\n{}\n\
                 Verifique se o executável PHP está instalado e disponível no PATH \
                 (ou ajuste o campo \"php_executable\" em {CONFIG_FILE}).",
                php.trim(),
                script.display(),
                source_dir,
                target_file,
                error,
            )));
            let _ = sender.unbounded_send(Message::Finished(None));
            return;
        }
    };

    stream_child(&mut child, stop, sender).await;
}

/// Acompanha a saída de um processo já iniciado, enviando cada linha para a
/// interface e, ao final, o código de saída.
async fn stream_child(
    child: &mut tokio::process::Child,
    stop: Arc<AtomicBool>,
    sender: mpsc::UnboundedSender<Message>,
) {
    let mut stdout = child.stdout.take().map(tokio::io::BufReader::new);
    let mut stderr = child.stderr.take().map(tokio::io::BufReader::new);

    let mut stdout_buffer = Vec::new();
    let mut stderr_buffer = Vec::new();
    let mut stdout_done = stdout.is_none();
    let mut stderr_done = stderr.is_none();

    while !stdout_done || !stderr_done {
        tokio::select! {
            result = read_chunk(&mut stdout, &mut stdout_buffer), if !stdout_done => {
                match result {
                    Ok(0) => stdout_done = true,
                    Ok(_) => {
                        let _ = sender.unbounded_send(Message::OutputLine(decode_line(&stdout_buffer)));
                    }
                    Err(error) => {
                        let _ = sender.unbounded_send(Message::OutputLine(format!(
                            "[erro ao ler a saída do processo: {error}]"
                        )));
                        stdout_done = true;
                    }
                }
            }
            result = read_chunk(&mut stderr, &mut stderr_buffer), if !stderr_done => {
                match result {
                    Ok(0) => stderr_done = true,
                    Ok(_) => {
                        let _ = sender.unbounded_send(Message::OutputLine(decode_line(&stderr_buffer)));
                    }
                    Err(error) => {
                        let _ = sender.unbounded_send(Message::OutputLine(format!(
                            "[erro ao ler a saída de erros do processo: {error}]"
                        )));
                        stderr_done = true;
                    }
                }
            }
            _ = tokio::time::sleep(STOP_POLL_INTERVAL) => {
                if stop.load(Ordering::Relaxed) {
                    let _ = child.start_kill();
                }
            }
        }
    }

    if stop.load(Ordering::Relaxed) {
        let _ = child.start_kill();
        let _ = sender.unbounded_send(Message::OutputLine(
            "\nExecução interrompida pelo usuário.".to_string(),
        ));
    }

    let code = match child.wait().await {
        Ok(status) => status.code(),
        Err(error) => {
            let _ = sender.unbounded_send(Message::ProcessError(format!(
                "Erro ao finalizar o processo: {error}"
            )));
            None
        }
    };

    let _ = sender.unbounded_send(Message::Finished(code));
}

/// Lê um pedaço (linha) de uma das saídas do processo, aguardando até que
/// algo seja escrito. Devolve `Ok(0)` no fim da saída.
async fn read_chunk<R>(
    reader: &mut Option<R>,
    buffer: &mut Vec<u8>,
) -> std::io::Result<usize>
where
    R: tokio::io::AsyncBufRead + Unpin + Send,
{
    buffer.clear();

    match reader {
        Some(reader) => reader.read_until(b'\n', buffer).await,
        None => std::future::pending().await,
    }
}

// ---------------------------------------------------------------------------
// Ponto de entrada
// ---------------------------------------------------------------------------

fn main() -> iced::Result {
    iced::application(App::new, App::update, App::view)
        .title(APP_TITLE)
        .window(window::Settings {
            size: iced::Size::new(980.0, 680.0),
            min_size: Some(iced::Size::new(780.0, 520.0)),
            ..window::Settings::default()
        })
        .run()
}

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    /// Verifica que as linhas de stdout e de stderr, bem como o código de
    /// saída, são encaminhadas para a interface.
    #[tokio::test]
    async fn encaminha_saida_e_codigo_de_saida() {
        let mut command = if cfg!(windows) {
            let mut command = tokio::process::Command::new("cmd");
            command.args(["/c", "echo linha-1 & echo linha-2 1>&2"]);
            command
        } else {
            let mut command = tokio::process::Command::new("sh");
            command.args(["-c", "echo linha-1; echo linha-2 1>&2"]);
            command
        };

        command
            .stdin(Stdio::null())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped());

        let mut child = command
            .spawn()
            .expect("não foi possível iniciar o processo de teste");

        let (sender, mut receiver) = mpsc::unbounded();
        stream_child(&mut child, Arc::new(AtomicBool::new(false)), sender).await;

        let mut linhas = Vec::new();
        let mut codigo = None;

        while let Ok(message) = receiver.try_recv() {
            match message {
                Message::OutputLine(line) => linhas.push(line),
                Message::Finished(code) => codigo = code,
                _ => {}
            }
        }

        assert!(
            linhas.iter().any(|linha| linha.contains("linha-1")),
            "saída lida: {linhas:?}"
        );
        assert!(
            linhas.iter().any(|linha| linha.contains("linha-2")),
            "saída lida: {linhas:?}"
        );
        assert_eq!(codigo, Some(0));
    }
}
