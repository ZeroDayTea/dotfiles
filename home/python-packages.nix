# per-project deps belong in that project's flake, not here
{ pkgs }:

pkgs.python3.withPackages (ps: with ps; [
  isort
  numpy
  pandas
  pip
  pwntools
  pycryptodome
  pytest
  setuptools
  torch
])
