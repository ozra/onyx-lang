make onyx -e stats=1 -e verbose=1 &&
    echo "onyx built!" &&
    CRYSTAL_PATH=./src \
      .build/onyx doc --stats --verbose --link-flags "-L/opt/crystal/embedded/lib" \
        docs/main.cr -o .build/docs/

