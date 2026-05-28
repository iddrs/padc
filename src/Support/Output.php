<?php

namespace Padc\Support;

class Output
{
    static public function println(string $msg = ''): void
    {
        echo $msg . PHP_EOL;
    }
}