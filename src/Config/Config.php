<?php

namespace Padc\Config;

use Padc\Support\Output;

class Config
{
    public string $sqlDirectory {
        get => $this->sqlDirectory;
        set(string $value) {
            if(!is_dir($value)){
                Output::println("$value não é um diretório.");
                exit();
            }
            if(!str_ends_with($value, '/') && !str_ends_with($value, '\\')) $value .= DIRECTORY_SEPARATOR;
            $this->sqlDirectory = $value;
        }
    }

    public string $cnpjCamara;
    public function __construct()
    {

    }
}