#!/usr/bin/env python3
"""Interface gráfica (GUI) para a ferramenta PADC.

Executa `php padc.php source_dir target_file` exibindo a saída do
console dentro da interface, com os parâmetros de execução
(executável PHP, diretório de origem e arquivo DuckDB de destino)
configuráveis pela GUI e persistidos entre sessões.
"""

from __future__ import annotations

import json
import os
import queue
import subprocess
import threading
import tkinter as tk
from tkinter import filedialog
from tkinter import messagebox
from tkinter import scrolledtext
from tkinter import ttk

APP_NAME = "PADC"
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PADC_SCRIPT = os.path.join(BASE_DIR, "padc.php")
CONFIG_FILE = os.path.join(BASE_DIR, "padc_gui_config.json")


def load_config() -> dict:
    defaults = {
        "php_executable": "php",
        "source_dir": "",
        "target_file": "",
    }
    try:
        with open(CONFIG_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, ValueError):
        data = {}
    for key in defaults:
        if key in data and isinstance(data[key], str):
            defaults[key] = data[key]
    return defaults


def save_config(config: dict) -> None:
    try:
        with open(CONFIG_FILE, "w", encoding="utf-8") as f:
            json.dump(config, f, ensure_ascii=False, indent=2)
    except OSError:
        pass


class PadcGUI:
    def __init__(self, root: tk.Tk) -> None:
        self.root = root
        self.queue: "queue.Queue[tuple[object, object]]" = queue.Queue()
        self.process: "subprocess.Popen | None" = None

        root.title(f"{APP_NAME} — Conversor de dados SIAPC/PAD para DuckDB")
        root.geometry("900x650")
        root.minsize(720, 460)

        cfg = load_config()

        self.var_php = tk.StringVar(value=cfg["php_executable"])
        self.var_source = tk.StringVar(value=cfg["source_dir"])
        self.var_target = tk.StringVar(value=cfg["target_file"])

        self._build_ui()
        self._poll_queue()

        root.protocol("WM_DELETE_WINDOW", self._on_close)

    def _build_ui(self) -> None:
        outer = ttk.Frame(self.root, padding=10)
        outer.pack(fill="both", expand=True)
        outer.columnconfigure(0, weight=1)
        outer.rowconfigure(1, weight=1)

        form = ttk.Frame(outer)
        form.grid(row=0, column=0, sticky="ew")
        form.columnconfigure(1, weight=1)

        rows = (
            ("Executável PHP:", self.var_php, self._browse_php),
            ("Diretório de origem:", self.var_source, self._browse_source),
            ("Arquivo de destino:", self.var_target, self._browse_target),
        )
        for i, (label, var, browse) in enumerate(rows):
            ttk.Label(form, text=label, justify="right").grid(
                row=i, column=0, sticky="e", padx=(0, 8), pady=4
            )
            ttk.Entry(form, textvariable=var).grid(
                row=i, column=1, sticky="ew", pady=4
            )
            ttk.Button(form, text="Procurar...", command=browse).grid(
                row=i, column=2, sticky="e", padx=(8, 0), pady=4
            )

        out_frame = ttk.Frame(outer)
        out_frame.grid(row=1, column=0, sticky="nsew", pady=(12, 8))

        self.output = scrolledtext.ScrolledText(
            out_frame,
            wrap="word",
            state="disabled",
            font=("Consolas", 10),
            relief="sunken",
            borderwidth=1,
        )
        self.output.pack(fill="both", expand=True)

        actions = ttk.Frame(outer)
        actions.grid(row=2, column=0, sticky="ew")
        actions.columnconfigure(0, weight=1)

        ttk.Button(actions, text="Limpar saída", command=self.clear_output).grid(
            row=0, column=1, padx=4, pady=4
        )
        self.run_button = ttk.Button(actions, text="Executar", command=self.run)
        self.run_button.grid(row=0, column=2, padx=4, pady=4)
        self.stop_button = ttk.Button(
            actions, text="Parar", command=self.stop, state="disabled"
        )
        self.stop_button.grid(row=0, column=3, padx=4, pady=4)

        self.status_var = tk.StringVar(value="Pronto.")
        status = ttk.Label(
            self.root,
            textvariable=self.status_var,
            relief="sunken",
            anchor="w",
            padding=(6, 2),
        )
        status.pack(fill="x", side="bottom")

    # --- Navegação por arquivos ---

    def _browse_php(self) -> None:
        path = filedialog.askopenfilename(
            title="Selecione o executável PHP",
            filetypes=[("Arquivo executável", "*.exe"), ("Todos os arquivos", "*.*")],
        )
        if path:
            self.var_php.set(path)

    def _browse_source(self) -> None:
        path = filedialog.askdirectory(title="Selecione o diretório de origem")
        if path:
            self.var_source.set(path)

    def _browse_target(self) -> None:
        path = filedialog.asksaveasfilename(
            title="Selecione o arquivo DuckDB de destino",
            defaultextension=".duckdb",
            filetypes=[("Arquivo DuckDB", "*.duckdb"), ("Todos os arquivos", "*.*")],
            confirmoverwrite=False,
        )
        if path:
            self.var_target.set(path)

    # --- Ações ---

    def run(self) -> None:
        if self.process is not None and self.process.poll() is None:
            return

        php = self.var_php.get().strip()
        source = self.var_source.get().strip()
        target = self.var_target.get().strip()

        if not php:
            messagebox.showerror("Parâmetros inválidos", "Informe o executável PHP.")
            return
        if not source:
            messagebox.showerror("Parâmetros inválidos", "Informe o diretório de origem.")
            return
        if not os.path.isdir(source):
            messagebox.showerror(
                "Parâmetros inválidos", f"O diretório de origem não existe:\n{source}"
            )
            return
        if not target:
            messagebox.showerror("Parâmetros inválidos", "Informe o arquivo de destino.")
            return

        self.save_current_config()

        self.output.configure(state="normal")
        self.output.delete("1.0", "end")
        self.output.configure(state="disabled")

        cmd = [php, PADC_SCRIPT, source, target]

        try:
            proc = subprocess.Popen(
                cmd,
                cwd=BASE_DIR,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                encoding="utf-8",
                errors="replace",
                bufsize=1,
            )
        except OSError as exc:
            messagebox.showerror(
                "Falha ao iniciar",
                f"Não foi possível executar o comando:\n{' '.join(cmd)}\n\n{exc}\n\n"
                f"Verifique se o executável PHP está correto.",
            )
            return

        self.process = proc
        self.status_var.set("Executando...")
        self.run_button.config(state="disabled")
        self.stop_button.config(state="normal")
        threading.Thread(target=self._reader, args=(proc,), daemon=True).start()

    def stop(self) -> None:
        proc = self.process
        if proc is not None and proc.poll() is None:
            try:
                proc.terminate()
            except OSError:
                pass
            self.status_var.set("Parando...")

    def clear_output(self) -> None:
        self.output.configure(state="normal")
        self.output.delete("1.0", "end")
        self.output.configure(state="disabled")
        self.status_var.set("Pronto.")

    def save_current_config(self) -> None:
        save_config(
            {
                "php_executable": self.var_php.get().strip(),
                "source_dir": self.var_source.get().strip(),
                "target_file": self.var_target.get().strip(),
            }
        )

    # --- Thread de leitura da saída ---

    def _reader(self, proc: subprocess.Popen) -> None:
        try:
            for line in proc.stdout:
                self.queue.put(("output", line))
            code = proc.wait()
        except Exception as exc:
            code = -1
            self.queue.put(("output", f"Erro na leitura da saída: {exc}\n"))
        self.queue.put(("done", code))

    # --- Fila e estado ---

    def _poll_queue(self) -> None:
        try:
            while True:
                kind, value = self.queue.get_nowait()
                if kind == "output":
                    self._append_output(str(value))
                elif kind == "done":
                    self._on_finished(int(value))
                elif kind == "error":
                    self._on_error(str(value))
        except queue.Empty:
            pass
        self.root.after(100, self._poll_queue)

    def _append_output(self, text: str) -> None:
        self.output.configure(state="normal")
        self.output.insert("end", text)
        self.output.see("end")
        self.output.configure(state="disabled")

    def _on_finished(self, code: int) -> None:
        self.process = None
        self.run_button.config(state="normal")
        self.stop_button.config(state="disabled")
        if code == 0:
            self.status_var.set("Concluído com sucesso.")
            self._append_output("\n\nProcesso concluído com sucesso.\n")
        else:
            self.status_var.set(f"Processo encerrado com o código de saída {code}.")
            self._append_output(f"\n\nProcesso encerrado com o código de saída {code}.\n")

    def _on_error(self, message: str) -> None:
        self.process = None
        self.run_button.config(state="normal")
        self.stop_button.config(state="disabled")
        self.status_var.set("Erro durante a execução.")
        self._append_output(f"\n\n{message}\n")

    def _on_close(self) -> None:
        self.save_current_config()
        proc = self.process
        if proc is not None and proc.poll() is None:
            try:
                proc.terminate()
            except OSError:
                pass
        self.root.destroy()


def main() -> None:
    root = tk.Tk()
    PadcGUI(root)
    root.mainloop()


if __name__ == "__main__":
    main()