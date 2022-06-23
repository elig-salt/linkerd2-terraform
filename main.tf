module "linkerd" {
  source = "./modules/linkerd" # debug with this

  linkerd_version = "2.11.1"
  enable_ha       = false
  include_jaeger  = true
  include_viz     = true
}
