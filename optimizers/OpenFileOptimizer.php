<?php

namespace Zephir\Optimizers\FunctionCall;

use Zephir\Call;
use Zephir\CompilationContext;
use Zephir\CompiledExpression;
use Zephir\Exception\CompilerException;
use Zephir\Optimizers\OptimizerAbstract;

class OpenFileOptimizer extends OptimizerAbstract
{
    public function optimize(array $expression, Call $call, CompilationContext $context)
    {
        if (!isset($expression['parameters'])) {
            throw new CompilerException("'open_file' requires 2 parameters. No arguments set.", $expression);
        }

        if (count($expression['parameters']) == 1) {
            throw new CompilerException("'open_file' requires 2 parameters. 2nd argument missing.", $expression);
        }

        if (count($expression['parameters']) > 2) {
            throw new CompilerException("'open_file' requires 2 parameters.", $expression);
        }

        /**
         * Process the expected symbol to be returned
         */
        $call->processExpectedReturn($context);

        $symbolVariable = $call->getSymbolVariable();
        if (!$symbolVariable->isInt()) {
            throw new CompilerException("File Descriptors only can be stored in int variables", $expression);
        }

        $context->headersManager->add('api/fd-api');

        $resolvedParams = $call->getReadOnlyResolvedParams($expression['parameters'], $context, $expression);

        return new CompiledExpression('int', "get_file_fd({$resolvedParams[0]},{$resolvedParams[1]})", $expression);
    }
}
