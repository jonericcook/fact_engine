# Fact Engine

### How to install Elixir

You can install `Elixir` by following the [official docs](https://elixir-lang.org/install.html#distributions) or via [asdf](https://www.pluralsight.com/guides/installing-elixir-erlang-with-asdf).

### How to use Fact Engine

1. Download the `fact_engine` zip file and unzip it
2. `cd` into it
3. If you are using `asdf` you'll need to run `asdf install`
4. Run `iex -S mix` to get to the interactive shell
5. Run `FactEngine.State.start()` (this starts the process that holds the persistent state)
6. Run `FactEngine.run(read_file_path, write_file_path)` where `write_file_path` is the file path to the file you want to process and `write_file_path` is the file path to the file you want the results written to.
   For example: `read_file_path = "/Users/jonericcook/github/fact_engine/examples/4/in.txt"` and `write_file_path = "/Users/jonericcook/github/fact_engine/examples/4/out.txt"`

### Example Run

Check the contents of the file that's to be processed

```
% cat /Users/jonericcook/github/fact_engine/examples/4/in.txt
INPUT make_a_triple (3, 4, 5)
INPUT make_a_triple (5, 12, 13)
QUERY make_a_triple (X, 4, Y)
QUERY make_a_triple (X, X, Y)
```

Start the Elixir interactive shell and use FactEngine

```
% iex -S mix
iex(1)> FactEngine.State.start()
iex(2)> read_file_path = "/Users/jonericcook/github/fact_engine/examples/4/in.txt"
iex(3)> write_file_path = "/Users/jonericcook/github/fact_engine/examples/4/out.txt"
iex(4)> FactEngine.run(read_file_path, write_file_path)
iex(5)> FactEngine.State.get
%{"make_a_triple" => #MapSet<[["12", "13", "5"], ["3", "4", "5"]]>}
```

Check the contents of the file that contains the results

```
% cat /Users/jonericcook/github/fact_engine/examples/4/out.txt
---
X: 3, Y: 5
---
false
```

### Comments about solution

In an effort to not have duplicates in `state` I chose to sort the arguments. I chose this because to me it wouldn't make sense to have two entries - one for `INPUT are_friends (alex, sam)` and one for `INPUT are_friends (sam, alex)`.

It was unclear how to create the constraint between the number of arguments and a statement therefore I opted to not verify the number of arguments for a given statement. For example `INPUT love (cat, dog)` and `INPUT love (cheese)` would both be accepted. As I read this I think I could handle that scenario by having a MapSet for each statement and each length of arguments provided with said statement. For example:

```
%{
    "loves" => %{
        2 => #MapSet<[["garfield", "lasagna"]]>,
        3 => #MapSet<[["garfield", "lasagna", "grilled_cheese"]]>
    }
}
```

Where the key at the second depth is the length of the lists in the `MapSet`.
