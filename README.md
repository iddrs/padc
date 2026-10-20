# padc
Outro conversor de arquivos *.txt do PAD, agora para DuckDB.

## Uso
```
php padc.php source_dir target_file
```

## Interface gráfica
Também é possível usar a ferramenta pela interface gráfica em Python:

```
python padc_gui.py
```

A GUI permite configurar o executável PHP, o diretório de origem e o arquivo
DuckDB de destino, exibe a saída do console em tempo real durante a execução
e mantém a última configuração executada entre sessões.

### Interface gráfica em Rust (Iced)
Há também uma interface gráfica nativa escrita em Rust com o
[Iced](https://iced.rs), no diretório `gui/`:

```
cd gui
cargo run --release
```

Para gerar o executável:

```
cd gui
cargo build --release
```

O executável ficará em `gui/target/release/padc-gui.exe`. Como ele executa o
`padc.php`, mantenha o executável gerado no diretório do projeto (ao lado de
`padc.php`) ou no diretório `gui/`. A GUI localiza o script automaticamente,
exibe a saída bruta do conversor em uma área com barra de rolagem e persiste
os parâmetros no mesmo `padc_gui_config.json` usado pela GUI em Python.
