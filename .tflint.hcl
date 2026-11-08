config {
  call_module_type = "none"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

rule "terraform_standard_module_structure" {
  enabled = false
}

rule "terraform_naming_convention" {
  enabled = false
}
