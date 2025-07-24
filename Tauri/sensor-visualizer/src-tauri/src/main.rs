#![cfg_attr(
  all(not(debug_assertions), target_os = "windows"),
  windows_subsystem = "windows"
)]


use rosc::{decoder::decode, OscMessage, OscPacket, OscType};
use std::net::UdpSocket;
use tauri::Manager;
use once_cell::sync::OnceCell;
use local_ip_address::local_ip;
use serde::Serialize;

static STARTED: OnceCell<()> = OnceCell::new();

#[derive(Serialize, Clone)]
struct OscArgWithValue {
    value: SerializableOscType,
}

#[derive(Serialize, Clone)]
#[serde(untagged)]
enum SerializableOscType {
    Int(i32),
    Float(f32),
    String(String),
}

#[derive(Serialize, Clone)]
struct SerializableOscMessage {
    addr: String,
    args: Vec<OscArgWithValue>,
}

fn to_serializable_osc_type(arg: &OscType) -> Option<SerializableOscType> {
    match arg {
        OscType::Int(i) => Some(SerializableOscType::Int(*i)),
        OscType::Float(f) => Some(SerializableOscType::Float(*f)),
        OscType::String(s) => Some(SerializableOscType::String(s.clone())),
        _ => None,
    }
}

#[tauri::command]
fn get_local_ip_address() -> String {
  let my_local_ip = local_ip().unwrap();
  my_local_ip.to_string()
}

fn handle_osc_message(msg: OscMessage, app_handle: &tauri::AppHandle) {
    let serializable_msg = SerializableOscMessage {
        addr: msg.addr,
        args: msg.args.iter().filter_map(|arg| {
            to_serializable_osc_type(arg).map(|val| OscArgWithValue { value: val })
        }).collect(),
    };

    //println!("Emitting OSC message: {:?}", serde_json::to_string(&serializable_msg).unwrap());

    if let Err(e) = app_handle.emit_all("osc-message", serializable_msg) {
        eprintln!("Failed to emit OSC message: {}", e);
    }
}

#[tauri::command]
async fn start_osc_listener(app_handle: tauri::AppHandle) {
    if STARTED.set(()).is_ok() {
        std::thread::spawn(move || {
            println!("OSC listener thread started");
            let sock = UdpSocket::bind("0.0.0.0:57121").expect("Failed to bind UDP socket");
            println!("UDP socket bound successfully");
            let mut buf = [0u8; 1024];
            loop {
                match sock.recv_from(&mut buf) {
                    Ok((size, addr)) => {
                        //println!("Received {} bytes from {}", size, addr);

                        match decode(&buf[..size]) {
                            Ok(packet) => match packet {
                                OscPacket::Message(msg) => {
                                    handle_osc_message(msg, &app_handle);
                                }
                                OscPacket::Bundle(bundle) => {
                                    //println!("Received OSC bundle with {} packets", bundle.content.len());
                                    for p in bundle.content {
                                        if let OscPacket::Message(msg) = p {
                                            handle_osc_message(msg, &app_handle);
                                        } else {
                                            println!("Nested bundle encountered (not handled)");
                                        }
                                    }
                                }
                            },
                            Err(e) => {
                                eprintln!("Failed to decode OSC packet: {}", e);
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
    .invoke_handler(tauri::generate_handler![start_osc_listener, get_local_ip_address])
    .run(tauri::generate_context!())
    .expect("error while running tauri application");
}
