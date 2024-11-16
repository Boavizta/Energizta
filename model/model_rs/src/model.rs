use std::collections::HashMap;

use schemars::JsonSchema;

/// The report to send to Energizta server.
#[derive(JsonSchema)]
pub struct EnergiztaReport {
    /// Information about the experiment: what is this report about?
    pub experiment: ExperimentInfo,

    /// Information about the hardware.
    ///
    /// This is heavily dependent on the use case, so we don't require _one_ particular type of component.
    /// You should fill at least the most relevant components (usually: CPU and GPU).
    pub hardware_spec: Vec<HardwareComponent>,

    /// Information about the software environment.
    pub software_spec: SoftwareSpec,

    /// Timestamped energy or performance measurements.
    pub measurements: Vec<Measurement>,
}

#[derive(JsonSchema)]
pub struct ExperimentInfo {
    pub r#type: String,
    pub description: String,
    pub details: Option<serde_json::Map<String, serde_json::Value>>,
}

#[derive(JsonSchema)]
pub struct SoftwareSpec {
    /// For example `Linux`.
    os_name: String,
    /// For example `6.8.0-48-generic`.
    os_version: String,
    /// For example `Ubuntu 22.04.4`.
    os_friendly_name: String,

    components: Vec<SoftwareComponent>,
}

#[derive(JsonSchema)]
pub struct SoftwareComponent {
    kind: String,
    name: String,
    provider: String,
}

#[derive(JsonSchema)]
pub struct HardwareComponent {
    pub kind: String,
    pub vendor: String,
    pub model: String,
    pub details: serde_json::value::Map<String, serde_json::Value>,
}

// TODO Factoriser les métadonnées des métriques pour optimiser la taille des données ?

#[derive(JsonSchema)]
pub struct Measurement {
    pub meta: MeasurementMeta,
    pub value: f64,
    pub timestamp_begin: String,
    pub timestamp_end: String,
    pub hardware_component_kind: String,
    pub hardware_component_id: String,
    pub details: HashMap<String, MeasurementDetail>,
}

#[derive(JsonSchema)]
pub struct MeasurementMeta {
    pub kind: MeasurementKind,
    pub unit: String,
    pub tool_name: String,
    pub tool_version: String,
    pub tool_details: Option<String>,
    pub error_margin: Option<String>,
}

#[derive(JsonSchema)]
#[serde(untagged)]
pub enum MeasurementDetail {
    String(String),
    Int(i64),
    Float(f64),
}

#[derive(JsonSchema)]
pub enum MeasurementKind {
    Performance,
    Energy,
    Other,
}

// #[derive(JsonSchema)]
// pub enum HardwareKind {
//     Cpu,
//     iGpu,
//     dGpu,
//     dRam,
//     Hdd,
//     Ssd,
//     Fan,
//     Custom(String),
// }
