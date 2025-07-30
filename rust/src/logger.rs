use tracing_subscriber::prelude::*;

#[cfg(any(target_os = "linux", target_os = "macos", target_os = "windows", target_os = "ios"))]
pub fn init() {
    use tracing_subscriber::filter::EnvFilter;

    let stdout_layer = tracing_subscriber::fmt::layer()
        .with_file(true)
        .with_line_number(true)
        .with_target(true)
        .with_level(true)
        .with_filter(EnvFilter::from_default_env())
        .boxed();

    if let Err(err) = tracing_subscriber::registry()
        .with(stdout_layer)
        .try_init() {
        eprintln!("Unable to setup logger: {err:?}");
    }
}

#[cfg(target_os = "android")]
pub fn init() {
    if let Err(err) = tracing_subscriber::registry()
        .with(tracing_android::layer("holiday_planner").expect("Unable to create android tracing layer"))
        .try_init() {
        eprintln!("Unable to setup logger: {err:?}");
    }
}
