add_property(   "lmod", "sticky")

require("os")
load("CCconfig")
load("gentoo/2020")

if (mode() == "spider") then
	-- set by gentoo/2020 module
	local arch = os.getenv("RSNT_ARCH")
	prepend_path("MODULEPATH", "/cvmfs/soft.computecanada.ca/easybuild/modules/2020/Core")
	prepend_path("MODULEPATH", pathJoin("/cvmfs/soft.computecanada.ca/easybuild/modules/2020", arch, "Core"))
	local user = os.getenv("USER","unknown")
	local home = os.getenv("HOME",pathJoin("/home",user))
	if user ~= "ebuser" then
		prepend_path("MODULEPATH", pathJoin(home, ".local/easybuild/modules/2020/Core"))
		prepend_path("MODULEPATH", pathJoin(home, ".local/easybuild/modules/2020", arch, "Core"))
	end
end

load("imkl/2020.1.217")
load("intel/2020.1.217")
load("openmpi/4.0.3")
