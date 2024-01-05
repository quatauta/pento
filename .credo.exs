# .credo.exs
%{
  configs: [
    %{
      checks: %{
        enabled: [
          # https://github.com/adobe/elixir-styler/blob/main/README.md#credo-rules-styler-replaces
          # Styler Rewrites
          #
          # The following rules are automatically rewritten by Styler and so disabled here to save time
          # Some of the rules have `priority: :high`, meaning Credo runs them unless we explicitly disable them
          # (removing them from this file wouldn't be enough, the `false` is required)
          #
          # Some rules have a comment before them explaining ways Styler deviates from the Credo rule.
          #
          # always expands `A.{B, C}`
          {Credo.Check.Consistency.MultiAliasImportRequireUse, false},
          # including `case`, `fn` and `with` statements
          {Credo.Check.Consistency.ParameterPatternMatching, false},
          {Credo.Check.Readability.AliasOrder, false},
          {Credo.Check.Readability.BlockPipe, false},
          # goes further than formatter - fixes bad underscores, eg: `100_00` -> `10_000`
          {Credo.Check.Readability.LargeNumbers, false},
          # adds `@moduledoc false`
          {Credo.Check.Readability.ModuleDoc, false},
          {Credo.Check.Readability.MultiAlias, false},
          {Credo.Check.Readability.OneArityFunctionInPipe, false},
          # removes parens
          {Credo.Check.Readability.ParenthesesOnZeroArityDefs, false},
          {Credo.Check.Readability.PipeIntoAnonymousFunctions, false},
          {Credo.Check.Readability.PreferImplicitTry, false},
          {Credo.Check.Readability.SinglePipe, false},
          # **potentially breaks compilation** - see **Troubleshooting** section below
          {Credo.Check.Readability.StrictModuleLayout, false},
          {Credo.Check.Readability.UnnecessaryAliasExpansion, false},
          {Credo.Check.Readability.WithSingleClause, false},
          {Credo.Check.Refactor.CaseTrivialMatches, false},
          {Credo.Check.Refactor.CondStatements, false},
          # in pipes only
          {Credo.Check.Refactor.FilterCount, false},
          # in pipes only
          {Credo.Check.Refactor.MapInto, false},
          # in pipes only
          {Credo.Check.Refactor.MapJoin, false},
          {Credo.Check.Refactor.NegatedConditionsInUnless, false},
          {Credo.Check.Refactor.NegatedConditionsWithElse, false},
          # allows ecto's `from
          {Credo.Check.Refactor.PipeChainStart, false},
          {Credo.Check.Refactor.RedundantWithClauseResult, false},
          {Credo.Check.Refactor.UnlessWithElse, false},
          {Credo.Check.Refactor.WithClauses, false}
        ]
      }
    }
  ]
}
