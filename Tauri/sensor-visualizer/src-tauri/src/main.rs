#![cfg_attr(
  all(not(debug_assertions), target_os = "windows"),
  windows_subsystem = "windows"
)]


use rosc::decoder::decode;
use rosc::OscPacket;
use std::net::UdpSocket;
use tauri::Manager;
use once_cell::sync::OnceCell;

static STARTED: OnceCell<()> = OnceCell::new();

#[tauri::command]
async fn start_osc_listener(app_handle: tauri::AppHandle) {
    // Only allow it to start once
    if STARTED.set(()).is_ok() {
        std::thread::spawn(move || {
            let sock = UdpSocket::bind("0.0.0.0:57121").expect("Failed to bind UDP socket");

            let mut buf = [0u8; 1024];
            loop {
                match sock.recv_from(&mut buf) {
                    Ok((size, _addr)) => {
                        if let Ok(packet) = decode(&buf[..size]) {
                            if let OscPacket::Message(msg) = packet {
                                let arg_strings: Vec<String> = msg.args.iter().map(|arg| format!("{:?}", arg)).collect();
                                let _ = app_handle.emit_all("osc-message", arg_strings);
                            }
                        }
                    }
                    Err(err) => {
                        eprintln!("Error receiving OSC: {}", err);
                    }
                }
            }
        });
    } else {
        println!("OSC listener already running; skipping.");
    }
}

fn main() {
  tauri::Builder::default()
    .invoke_handler(tauri::generate_handler![start_osc_listener])
    .run(tauri::generate_context!())
    .expect("error while running tauri application");
}
