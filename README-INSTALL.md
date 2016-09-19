Just run `make bootstrap`.

Missing deps will then be installed for Debian derivative system (Ubuntu among 
others) and the compiler will then be built in release mode (optimized).

Done!
Hopefully.

There's a dependency on ruby, because that's the lang the script was PR'ed with.
You're welcome to PR with a bash-only solution. And/or more target operating
systems.

