{
  description = ''
    https://github.com/animdustry-moe/massdriver-chan
    Discord bot to manage posts for Astro the static blog framework.

    Copyright 2026 animdustry.moe

    Licensed under the Apache License, Version 2.0 (the "License");         }
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
  '';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixche.url = "github:ezjfc/nixche";
  };

  outputs = inputs: inputs.flake-utils.lib.eachDefaultSystem (system: let
    overlay = inputs.nixche.overlays.neovim-with-lsps;
    pkgs = inputs.nixpkgs.legacyPackages.${system}.extend overlay;
    buildInputs = with pkgs; [
      elixir_1_19
    ];
    packages = with pkgs; [
    ] ++ buildInputs;
    shellHook = ''
      set -o allexport
      source .env
      set +o allexport

      alias doc="cat ${docs} | fzf | awk '{print $2}' | xargs xdg-open"
    '';

    docs = pkgs.writeText "docs.txt" ''
      https://docs.discord.com/developers/bots/overview
      https://hexdocs.pm/nostrum/intro.html
    '';
  in {
    devShells.default = pkgs.mkShellNoCC {
      inherit packages shellHook;
    };

    devShells.neovim = pkgs.mkShellNoCC {
      inherit shellHook;

      packages = packages ++ [
        (pkgs.neovim.withLsps {
          elixirls = pkgs.elixir-ls;
        })
      ];
    };
  });
}
