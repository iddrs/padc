<?php

use Padc\Processor;
use Padc\Support\Output;
use Saturio\DuckDB\DuckDB;
use Saturio\DuckDB\DB\Configuration;
use Padc\Config\Config;

// Prepara o ambiente

$cnpjCamara = '12292535000162';

$acceptableSourceFiles = [
    'empenho',
    'liquidac',
    'pagament',
    'bal_rec',
    'receita',
    'bal_desp',
    'tce_4111',
    'bal_ver',
    'bver_enc',
    'rd_extra',
    'decreto',
    'orgao',
    'uniorcam',
    'programa',
    'projativ',
    'rubrica',
    'recurso',
    'credor',
    'cta_disp',
];

$start_time = new DateTimeImmutable();

// Carrega as bibliotecas necessárias
require 'vendor/autoload.php';

// Imprime cabeçalho
Output::println('PADC -- Conversor de dados dos *.txt do SIAPC/PAD para DuckDB.');
Output::println('Desenvolvido por Everton da Rosa <everton3x@gmail.com>');
Output::println('==============================================================');
Output::println();

// Verifica se recebeu argumentos obrigatórios da linha de comando
$argSourceDir = $argv[1] ?? null;
$argTargetFile = $argv[2] ?? null;

// Se faltarem argumentos, mostra a ajuda e sai
if(is_null($argSourceDir) || is_null($argTargetFile)) {
    Output::println('Como utilizar');
    Output::println();
    Output::println('padc source_dir target_file');
    Output::println();
    Output::println('Parâmetros');
    Output::println("\tsource_dir\tDiretório onde estão os *.txt.");
    Output::println("\t\t\tOs arquivos serão procurados nos diretórios e subdiretórios.");
    Output::println("\ttarget_file\tCaminho para o arquivo DuckDB.");
    Output::println("\t\t\tSe o orquivo não existir, será criado automaticamente.");
    exit();
}

// Busca todos os arquivos *.txt
$sourceDirPattern = realpath($argSourceDir);

// Testa se $argSourceDir é um diretório
if(!is_dir($sourceDirPattern)) {
    Output::println("$sourceDirPattern não é um diretório.");
    exit();
}

// Busca os arquivos recursivamente
$sourceFiles = [];
$dirIterator = new RegexIterator(
    new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator($sourceDirPattern, RecursiveDirectoryIterator::SKIP_DOTS)), '/^.+\.txt$/i', RecursiveRegexIterator::GET_MATCH);
foreach ($dirIterator as $item) {
        if(array_search(basename(strtolower($item[0]), '.txt'), $acceptableSourceFiles) !== false) {
            $sourceFiles[] = realpath($item[0]);
        }
}

// Conectando com o arquivo DuckDB
$duckConfig = new Configuration();
$duckConfig->set('access_mode', 'READ_WRITE');
$duck = DuckDB::create($argTargetFile, config: $duckConfig);

$config = new Config();
$config->sqlDirectory = __DIR__ . DIRECTORY_SEPARATOR . 'sql' . DIRECTORY_SEPARATOR;
$config->cnpjCamara = $cnpjCamara;

$processor = new Processor($config, $sourceFiles, $duck);
$processor->run();

$end_time = new DateTimeImmutable();

$duration = $start_time->diff($end_time);

Output::println("Tempo decorrido de processamento: {$duration->format('%H horas, %I minutos e %S segundos')}");