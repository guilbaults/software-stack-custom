help([[Gentoo prefix is Gentoo Linux installed in a prefix ($EPREFIX) - Homepage: https://wiki.gentoo.org/wiki/Project:Prefix]])
whatis("Gentoo prefix is Gentoo Linux installed in a prefix ($EPREFIX) - Homepage: https://wiki.gentoo.org/wiki/Project:Prefix")

local root = "/cvmfs/soft.computecanada.ca/gentoo/2019"
local cc_cluster = os.getenv("CC_CLUSTER") or "computecanada"
local arch = os.getenv("RSNT_ARCH") or ""
local interconnect = os.getenv("RSNT_INTERCONNECT") or ""

if not arch or arch == "" then
	if cc_cluster == "cedar" or cc_cluster == "graham" or cc_cluster == "computecanada" then
		arch = "avx2"
	elseif cc_cluster == "beluga" then
		arch = "avx512"
	end
end
if not interconnect or interconnect == "" then
	if cc_cluster == "cedar" then
		interconnect = "omnipath"
	else
		interconnect = "infiniband"
	end
end

add_property(   "lmod", "sticky")

setenv("EPREFIX", root)

prepend_path("PATH", pathJoin(root, "bin"))
prepend_path("PATH", pathJoin(root, "sbin"))
prepend_path("PATH", pathJoin(root, "usr/bin"))
prepend_path("PATH", pathJoin(root, "usr/sbin"))
prepend_path("PATH", "/cvmfs/soft.computecanada.ca/custom/bin")
prepend_path("INFOPATH", pathJoin(root, "usr/share/info"))
prepend_path("INFOPATH", pathJoin(root, "usr/share/binutils-data/x86_64-pc-linux-gnu/2.31.1/info"))
prepend_path("INFOPATH", pathJoin(root, "usr/share/gcc-data/x86_64-pc-linux-gnu/8.2.0/info"))
prepend_path("MANPATH", pathJoin(root, "usr/share/man"))
prepend_path("MANPATH", pathJoin(root, "usr/share/binutils-data/x86_64-pc-linux-gnu/2.31.1/man"))
prepend_path("MANPATH", pathJoin(root, "usr/share/gcc-data/x86_64-pc-linux-gnu/8.2.0/man"))
prepend_path("PKG_CONFIG_PATH", pathJoin(root, "usr/share/pkgconfig"))
prepend_path("PKG_CONFIG_PATH", pathJoin(root, "usr/lib64/pkgconfig"))
prepend_path("PYTHONPATH", "/cvmfs/soft.computecanada.ca/custom/python/site-packages")
pushenv("SHELL", pathJoin(root, "bin/bash"))
pushenv("PAGER", "less -R")
pushenv("LESS", "-R -M --shift 5")
pushenv("LESSOPEN", "|lesspipe %s")
pushenv("CONFIG_PROTECT_MASK", "/etc/sandbox.d " .. pathJoin(root, "etc/gentoo-release") .. "/etc/terminfo /etc/ca-certificates.conf")
pushenv("GCC_SPECS", "")
pushenv("XDG_DATA_DIRS", pathJoin(root, "usr/share"))

require("os")
-- Define RSNT variables
-- do something only at load time, if not already defined. Otherwise, unloading the module will lose the predefined value if there is one
if mode() == "load" then
	setenv("RSNT_ARCH", arch)
end
if mode() == "load" then
	setenv("RSNT_INTERCONNECT", interconnect)
end
if os.getenv("SLURM_TMPDIR") and (not os.getenv("TMPDIR") or os.getenv("TMPDIR") == "/tmp") then
	setenv("TMPDIR", os.getenv("SLURM_TMPDIR"))
end

-- let pip use our wheel house
if arch == "avx512" then
        setenv("PIP_CONFIG_FILE", "/cvmfs/soft.computecanada.ca/config/python/pip-avx512.conf")
elseif arch == "avx2" then
        setenv("PIP_CONFIG_FILE", "/cvmfs/soft.computecanada.ca/config/python/pip-avx2.conf")
elseif arch == "avx" then
        setenv("PIP_CONFIG_FILE", "/cvmfs/soft.computecanada.ca/config/python/pip-avx.conf")
else
        setenv("PIP_CONFIG_FILE", "/cvmfs/soft.computecanada.ca/config/python/pip.conf")
end

-- also make easybuild and easybuild-generated modules accessible
prepend_path("PATH", "/cvmfs/soft.computecanada.ca/easybuild/bin")
setenv("EASYBUILD_CONFIGFILES", "/cvmfs/soft.computecanada.ca/easybuild/config.cfg")
setenv("EASYBUILD_BUILDPATH", pathJoin("/dev/shm", os.getenv("USER")))

setenv("EBROOTGENTOO", root)
setenv("EBVERSIONGENTOO", "2019")

if (mode() ~= "spider") then -- for now
	prepend_path("MODULEPATH", "/cvmfs/soft.computecanada.ca/easybuild/modules/2017/Core")
end

local user = os.getenv("USER","unknown")
local home = os.getenv("HOME",pathJoin("/home",user))
if user ~= "ebuser" then
    prepend_path("MODULEPATH", pathJoin(home, ".local/easybuild/modules/2017/Core"))
end

-- define PROJECT and SCRATCH environments
local posix = require("posix")
local stat = posix.stat

local def_scratch_dir = pathJoin("/scratch",user)
local def_project_link = pathJoin(home,"project")
local project_dir = nil

-- if we are in a job, define the project directory based on the SLURM project if it exists
local account = os.getenv("SLURM_JOB_ACCOUNT")
local jobid = os.getenv("SLURM_JOBID")
if false and jobid then
	local account = os.getenv("SLURM_JOB_ACCOUNT")
	if account then
		-- remove the _cpu or _gpu suffixes
		account = account:gsub("^(.*)_cpu$","%1")
		account = account:gsub("^(.*)_gpu$","%1")
	
		local test_project_link = pathJoin(home,"projects",account)
		-- test if there is such a project link
		if stat(test_project_link,"type") == "link" then
			-- find the directory this link points to
			project_dir = subprocess("readlink " .. test_project_link)
		end
	end
end
-- if project_dir was not found based on SLURM_JOB_ACCOUNT, test the default project 
project_dir = def_project_link
if not project_dir and stat(def_project_link,"type") == "link" then
	-- find the directory this link points to
	project_dir = subprocess("readlink " .. def_project_link)
end
if project_dir then
	-- if PROJECT is not defined, or if it was defined by us previously (i.e. in the login environment), define it
	if not os.getenv("PROJECT") or os.getenv("PROJECT") == os.getenv("CC_PROJECT") then
		setenv("PROJECT", project_dir)
	end
	-- define CC_PROJECT nevertheless
	setenv("CC_PROJECT", project_dir)
end
-- do not overwrite the environment variable if it already exists
if not os.getenv("SCRATCH") then
--	if stat(def_scratch_dir,"type") == "directory" then
		setenv("SCRATCH", def_scratch_dir)
--	end
end

-- if SLURM_TMPDIR is set, define TMPDIR to use it unless TMPDIR was already set to something different than /tmp
if os.getenv("SLURM_TMPDIR") and (not os.getenv("TMPDIR") or os.getenv("TMPDIR") == "/tmp") then
	setenv("TMPDIR", os.getenv("SLURM_TMPDIR"))
	setenv("LOCAL_SCRATCH", os.getenv("SLURM_TMPDIR"))
end


-- if SQUEUE_FORMAT is not already defined, define it
if not os.getenv("SQUEUE_FORMAT") then
	setenv("SQUEUE_FORMAT","%.8i %.8u %.12a %.14j %.3t %16S %.10L %.5D %.4C %.10b %.7m %N (%r) ")
end

-- if SQUEUE_SORT is not already defined, define it
if not os.getenv("SQUEUE_SORT") then
	setenv("SQUEUE_SORT", "-t,e,S")
end

-- if SACCT_FORMAT is not already defined, define it
if not os.getenv("SACCT_FORMAT") then
	setenv("SACCT_FORMAT","Account,User,JobID,Start,End,AllocCPUS,Elapsed,AllocTRES%30,CPUTime,AveRSS,MaxRSS,MaxRSSTask,MaxRSSNode,NodeList,ExitCode,State%20")
end
set_alias("quota", "diskusage_report")

