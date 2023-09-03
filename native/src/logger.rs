use tracing_subscriber::prelude::*;

#[cfg(any(target_os = "linux", target_os = "macos", target_os = "windows"))]
pub fn init() {
    use tracing_subscriber::filter::EnvFilter;

    let stdout_layer = tracing_subscriber::fmt::layer()
        .with_file(true)
        .with_line_number(true)
        .with_target(true)
        .with_level(true)
        .with_filter(EnvFilter::from_default_env())
        .boxed();

    tracing_subscriber::registry()
        .with(stdout_layer)
        .init();

}

#[cfg(target_os = "android")]
pub fn init() {
    tracing_subscriber::registry()
        .with(tracing_android::layer("holiday_planner").expect("Unable to create android tracing layer"))
        .init();
}
