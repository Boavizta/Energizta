use schemars::schema_for;

mod model;

fn main() {
    // generate the schema
    let schema = schema_for!(model::EnergiztaReport);
    println!("{}", serde_json::to_string_pretty(&schema).unwrap());   
}
