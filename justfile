default: gen lint

gen:
    flutter pub get
    CPATH="$(clang -v 2>&1 | grep "Selected GCC installation" | rev | cut -d' ' -f1 | rev)/include" flutter_rust_bridge_codegen

lint:
    cd native && cargo fmt
    dart format .

clean:
    flutter clean
    cd native && cargo clean
    
serve *args='':
    flutter pub run flutter_rust_bridge:serve {{args}}

splash_screen:
    flutter pub run flutter_native_splash:create

launcher_icon:
    flutter pub run flutter_launcher_icons

# vim:expandtab:sw=4:ts=4
