# Exmachina

Exmachina is a Finite State Machine engine.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `exmachina` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:exmachina, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/exmachina](https://hexdocs.pm/exmachina).

## Run Tests

mix test test/door_code_test/exmachina_door_test.exs

mix test test/sequence_generator/generator_test.ex 

mix test test/cat_fsm/exmachina_cat_test.exs