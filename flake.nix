{
  description = "Elliptic-curve research toolkit";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/master";

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };

      pariData = pkgs.symlinkJoin {
        name = "pari-data";
        paths = with pkgs; [
          pari-galdata
          pari-seadata-small
        ];
      };

      # Standalone gp only finds galdata/seadata through GP_DATA_DIR.
      pariWithData = pkgs.symlinkJoin {
        name = "pari-with-data-${pkgs.pari.version}";
        paths = [ pkgs.pari ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          for prog in $out/bin/gp $out/bin/gp-*; do
            wrapProgram "$prog" --set-default GP_DATA_DIR ${pariData}/share/pari
          done
        '';
      };

      toolkit = pkgs.buildEnv {
        name = "elliptic-curve-tools";
        paths = with pkgs; [
          # Number theory and elliptic curves
          pariWithData
          pariData
          gp2c
          ratpoints
          eclib
          sympow
          lcalc
          ecm
          primecount
          primesieve
          fplll
          msolve

          # Computer algebra systems
          # Skip the multi-hour doctest suite, which nixpkgs otherwise
          # requires to pass before sage can be used.
          (sage.override { requireSageTests = false; })
          gap
          singular
          maxima
          giac
          macaulay2

          # Numerical and statistical computing
          # Official upstream binaries; the source-built `julia` is not cached.
          julia-bin
          R

          # Data and database tools
          duckdb
          parquet-tools
          sqlite

          # Polyhedral geometry and optimisation
          polymake
          normaliz
          gfan
          palp
          lrs
          cddlib
          glpk
          highs
          soplex
        ];

        # The mathematical systems share some executable and data names.
        ignoreCollisions = true;
      };
    in
    {
      packages.${system} = {
        default = toolkit;
        elliptic-curve-tools = toolkit;
      };
    };
}
