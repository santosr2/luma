--- Version information for Luma
-- @module luma.version

local version = {
	major = 0,
	minor = 1,
	patch = 0,
	pre = "rc.5",
}

--- Version string
version.string =
	string.format("%d.%d.%d%s", version.major, version.minor, version.patch, version.pre and ("-" .. version.pre) or "")

--- Full version with name
version.full = "Luma " .. version.string

return version
