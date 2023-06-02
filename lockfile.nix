{ lib
, runCommand
, remarshal
, fetchurl
, ...
}:

with lib;
let
  getName = fullname: init (splitString "@" (last (tail (splitString "/" fullname))));
  fixVersion = ver: head (splitString "_" ver);
  getVersion = fullname: fixVersion (last (splitString "@" (last (tail (splitString "/" fullname)))));
  getScope = fullname: init (tail (splitString "/" fullname));
  getPath = fullname: (concatStringsSep "/" (flatten [(getScope fullname) (getName fullname)]));
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
          fetchurl {
            url = "${registry}/${path}/-/${name}-${version}.tgz";
            sha512 = v.resolution.integrity;
          }
        )
        (parseLockfile lockfile).packages
    );

}
