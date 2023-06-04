{ lib
, runCommand
, remarshal
, fetchurl
, ...
}:

with lib;
let
  getName = fullname: head (builtins.split "@" (last (builtins.split "/" fullname)));
  fixVersion = ver: head (builtins.split "_" ver);
  getVersion = fullname: fixVersion (last (builtins.split "@" (last (tail (builtins.split "/" fullname)))));
  getScope = fullname: head (builtins.split "/" fullname);
  getPath = fullname: (concatStringsSep "/" [(getScope fullname) (getName fullname)]);
in
rec {

  parseLockfile = lockfile: builtins.fromJSON (readFile (runCommand "toJSON" { } "${remarshal}/bin/yaml2json ${lockfile} $out"));

  dependencyTarballs = { registry, lockfile }:
    unique (
      mapAttrsToList
        (n: v:
          let
            path = getPath n;
            name = getName name;
            version = getVersion n;
          in
          (builtins.trace n); 
          fetchurl {
            url = "${registry}/${path}/-/${name}-${version}.tgz";
            sha512 = v.resolution.integrity;
          }
        )
        (parseLockfile lockfile).packages
    );

}
