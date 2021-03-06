# Copyright 2021 Xanadu Quantum Technologies Inc.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
r"""
This module contains the :class:`~.PLextQubit` class, a PennyLane simulator device that
interfaces with Julia for fast linear algebra calculations.
"""
from warnings import warn

import numpy as np
from pennylane import (
    BasisState,
    DeviceError,
    QuantumFunctionError,
    QubitStateVector,
    QubitUnitary,
)
import pennylane as qml
from pennylane.devices import DefaultQubit
from pennylane.operation import Expectation

try:
    import _PyPLext as plextlib

    from plextlib import *

    CPP_BINARY_AVAILABLE = True
except ModuleNotFoundError:
    CPP_BINARY_AVAILABLE = False

UNSUPPORTED_PARAM_GATES_ADJOINT = (
    "MultiRZ",
    "IsingXX",
    "IsingYY",
    "IsingZZ",
    "SingleExcitation",
    "SingleExcitationPlus",
    "SingleExcitationMinus",
    "DoubleExcitation",
    "DoubleExcitationPlus",
    "DoubleExcitationMinus",
)

class PLextQubit(DefaultQubit):
    """PennyLane PLext device.
    An extension of PennyLane's built-in ``default.qubit`` device that interfaces with Julia to
    perform fast linear algebra calculations.
    Use of this device requires pre-built binaries or compilation from source. Check out the
    :doc:`/installation` guide for more details.
    Args:
        wires (int): the number of wires to initialize the device with
        shots (int): How many times the circuit should be evaluated (or sampled) to estimate
            the expectation values. Defaults to ``None`` if not specified. Setting
            to ``None`` results in computing statistics like expectation values and
            variances analytically.
    """

    name = "PLext Qubit PennyLane plugin"
    short_name = "plext.qubit"
    pennylane_requires = ">=0.18"
    author = "Xanadu Inc."

    def __init__(self, wires, *, shots=None):
        super().__init__(wires, shots=shots)

    @classmethod
    def capabilities(cls):
        capabilities = super().capabilities().copy()
        capabilities.update(
            model="qubit",
            supports_reversible_diff=False,
            supports_inverse_operations=True,
            supports_analytic_computation=True,
            returns_state=True,
        )
        capabilities.pop("passthru_devices", None)
        return capabilities

    def apply(self, operations, rotations=None, **kwargs):

        # State preparation is currently done in Python
        if operations:  # make sure operations[0] exists
            if isinstance(operations[0], QubitStateVector):
                self._apply_state_vector(operations[0].parameters[0].copy(), operations[0].wires)
                del operations[0]
            elif isinstance(operations[0], BasisState):
                self._apply_basis_state(operations[0].parameters[0], operations[0].wires)
                del operations[0]

        for operation in operations:
            if isinstance(operation, (QubitStateVector, BasisState)):
                raise DeviceError(
                    "Operation {} cannot be used after other Operations have already been "
                    "applied on a {} device.".format(operation.name, self.short_name)
                )

        if operations:
            self._pre_rotated_state = self.apply_plext(self._state, operations)
        else:
            self._pre_rotated_state = self._state

        if rotations:
            if any(isinstance(r, QubitUnitary) for r in rotations):
                super().apply(operations=[], rotations=rotations)
            else:
                self._state = self.apply_plext(np.copy(self._pre_rotated_state), rotations)
        else:
            self._state = self._pre_rotated_state

    def apply_plext(self, state, operations):
        """Apply a list of operations to the state tensor.
        Args:
            state (array[complex]): the input state tensor
            operations (list[~pennylane.operation.Operation]): operations to apply
        Returns:
            array[complex]: the output state tensor
        """
        assert state.dtype == np.complex128
        state_vector = np.ravel(state)

        for o in operations:
            name = o.name.split(".")[0]  # The split is because inverse gates have .inv appended
            method = getattr(plextlib, name, None)

            wires = self.wires.indices(o.wires)

            if method is None:
                # Inverse can be set to False since o.matrix is already in inverted form
                sim.applyMatrix(o.matrix, wires, False)
            else:
                inv = o.inverse
                param = o.parameters
                method(state_vector, wires, inv, param)

        return np.reshape(state_vector, state.shape)
