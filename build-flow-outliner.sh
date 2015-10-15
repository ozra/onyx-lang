make onyx -e stats=1 -e verbose=1 &&
    echo "onyx built!" &&
    CRYSTAL_PATH=./src \
      .build/onyx devel --stats --verbose --link-flags "-L/opt/crystal/embedded/lib" \
        ./spec/onyx-compiler/compiler-flow-outliner.ox -o .build/compiler-flow-outliner


