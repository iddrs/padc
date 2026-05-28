<?php

namespace Padc;

use Padc\Config\Config;
use Saturio\DuckDB\DuckDB;
use Padc\Support\Output;

class Processor
{

    private array $context = [];
    public function __construct(
        private Config $config,
        private readonly array $sources,
        private readonly DuckDB $db)
    {

    }

    public function run(): void
    {
        Output::println(sprintf('Iniciando o processamento de %d arquivos...', count($this->sources)));

        $this->createCacheIfNotExists();
        $this->clearCache();
        $this->readRawData();
        $sqlFiles = $this->loadSqlList();
        $this->processSqlFiles($sqlFiles);

    }

    private function processSqlFiles(array $files): void
    {
        foreach ($files as $f) {
            Output::println("Processando $f");
            $sql = $this->applyContext(file_get_contents($f));
            $this->db->query($sql);
        }
    }

    private function applyContext(string $str): string
    {
        $search = array_keys($this->context);
        $replace = array_values($this->context);
        return str_replace($search, $replace, $str);
    }
    private function loadSqlList(): array
    {
        Output::println('Carregando arquivos SQL...');
        $files = glob("{$this->config->sqlDirectory}*.sql");
        sort($files);
        return $files;

    }

    private function readRawData(): void
    {
        foreach ($this->sources as $source) {
            Output::println("Carregando {$source}");
            $arquivo = basename(strtolower($source), '.txt');
            $fh = fopen($source, 'r');
            $header = $this->parseSourceHeader(fgets($fh));
            while (!feof($fh)) {
                $raw_data = trim(fgets($fh));
                $encoding = mb_detect_encoding($raw_data, ['UTF-8', 'ISO-8859-1', 'Windows-1252']);
                $raw_data = mb_convert_encoding($raw_data, 'UTF-8', $encoding);
                if(str_starts_with(strtolower($raw_data), 'finalizador')){
                    break;
                }
                $sql = <<<SQL
                insert into cache (arquivo, remessa, entidade, raw_data)
                values ('$arquivo', {$header['remessa']}, '{$header['entidade']}', '$raw_data');
                SQL;
                $this->db->query($sql);
            }
        }
    }

    private function parseSourceHeader(string $raw): array
    {
        $cnpj = substr($raw, 0, 14);
        $entidade = null;
        if($cnpj === $this->config->cnpjCamara){
            $entidade = 'cm';
        }
        $remessa = substr($raw, 26, 4).substr($raw, 24, 2);
        $this->context['{{remessa}}'] = (int) $remessa;
        $this->context['{{exercicio}}'] = (int) substr($remessa, 0, 4);
        return [
            'remessa' => (int) $remessa,
            'entidade' => $entidade,
        ];
    }

    private function clearCache(): void
    {
        Output::println('Limpando o cache...');
        $sql = <<<SQL
        delete from cache;
        SQL;
        $this->db->query($sql);
    }
    private function createCacheIfNotExists(): void
    {
        Output::println('Criando o cache...');
        $sql = <<<SQL
        create table if not exists
        cache
        (
            arquivo varchar(8),
            remessa uinteger,
            entidade varchar(4),
            raw_data varchar
        );
        SQL;
        $this->db->query($sql);
    }

}