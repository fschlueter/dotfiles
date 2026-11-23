# ~/.ipython/profile_default/startup/00-imports.py
import numpy as np
import matplotlib.pyplot as plt

try:  # NuRadio is only installed in the envs ($ENVS_DIR), not in Homebrew's python
    from NuRadioReco.utilities import units, constants as cons
except ImportError:
    pass
