#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Apply the upstream 1053 installation repair after a diagnosed timeout."""
from pathlib import Path
from types import SimpleNamespace
import importlib.util
import os

project = Path(__file__).resolve().parent.parent
prefix = Path(os.environ.get("INVENTOR_PREFIX", Path.home() / ".local/share/bottles/bottles/Inventor2027"))
state = Path(os.environ.get("INVENTOR_STATE_DIR", project))
logs = list((prefix / "drive_c/users").glob("*/AppData/Local/Temp/installbuilder_installer*.log"))
diagnosed = [p for p in logs if "LIC-INST-ERROR-69009748" in p.read_text(errors="replace")
             and "error code 1053" in p.read_text(errors="replace")]
if not diagnosed:
    raise SystemExit("No diagnosed new-install service timeout; refusing to mark a step complete")
services = list((prefix / "drive_c/Program Files (x86)/Common Files/Autodesk Shared/AdskLicensing")
                .glob("*/AdskLicensingService/AdskLicensingService.exe"))
if not services:
    raise SystemExit("The actual Autodesk Licensing Service executable is absent")
os.environ["INV_LOGDIR"] = str(state / "logs")
source = project / "vendor/inventor-linux/scripts/install-from-image.py"
spec = importlib.util.spec_from_file_location("image_installer", source)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
args = SimpleNamespace(image=str(state / "build/install-media"), prefix=str(prefix), lang="ja-JP", dry_run=False)
installer = module.Installer(args)
steps, _, missing = module.odis.plan(module.odis.Image(args.image), ["inventor"], "ja-JP")
if missing or not installer.finish_licensing():
    raise SystemExit("Licensing service installation repair failed")
step = next(s for s in steps if s["name"].lower() == "adsklicensing")
installer.mark_done(step["manifest"])
print("Applied documented Wine service-timeout repair; subsequent MSI steps start the real service executable.")
