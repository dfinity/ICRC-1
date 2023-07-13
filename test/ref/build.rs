use std::{io::Result, path::PathBuf};
fn main() -> Result<()> {
    std::env::set_var("PROTOC", protobuf_src::protoc());
    Ok(())
}
