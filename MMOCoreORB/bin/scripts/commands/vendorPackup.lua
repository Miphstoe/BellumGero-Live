-- Player-facing: no characterAbility. Ownership is validated server-side per vendor.
-- (status/recover subcommands check the "admin" ability inside VendorPackupCommand.)
VendorPackupCommand = {
	name = "vendorpackup",
}

AddCommand(VendorPackupCommand)
