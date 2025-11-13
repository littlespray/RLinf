# Copyright 2025 The RLinf Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
import dataclasses
import pathlib

import openpi.models.model as _model
import openpi.transforms as _transforms
from openpi.training.config import DataConfig, DataConfigFactory, ModelTransformFactory
from typing_extensions import override

from rlinf.models.embodiment.openpi.policies import behavior_policy


@dataclasses.dataclass(frozen=True)
class BehaviorDataConfig(DataConfigFactory):
    """
    This config is used to configure transforms for the Behavior-1K environment with 23-dimensional actions.
    """

    extra_delta_transform: bool = False

    @override
    def create(
        self, assets_dirs: pathlib.Path, model_config: _model.BaseModelConfig
    ) -> DataConfig:
        # The repack transform is *only* applied to the data coming from the dataset,
        # and *not* during inference.
        repack_transform = _transforms.Group(
            inputs=[
                _transforms.RepackTransform(
                    {
                        "observation/image": "image",
                        "observation/wrist_image": "wrist_image",
                        "observation/state": "state",
                        "actions": "actions",
                        "prompt": "prompt",
                    }
                )
            ]
        )

        # The data transforms are applied to the data coming from the dataset *and* during inference.
        data_transforms = _transforms.Group(
            inputs=[behavior_policy.BehaviorInputs(model_type=model_config.model_type)],
            outputs=[behavior_policy.BehaviorOutputs()],
        )

        # Behavior environment uses absolute actions, so we may need delta conversion
        # For now, we don't apply it since we need to check the actual action format
        if self.extra_delta_transform:
            # Assuming first 22 actions are joints/positions and last 1 is gripper
            delta_action_mask = _transforms.make_bool_mask(22, -1)
            data_transforms = data_transforms.push(
                inputs=[_transforms.DeltaActions(delta_action_mask)],
                outputs=[_transforms.AbsoluteActions(delta_action_mask)],
            )

        # Model transforms include things like tokenizing the prompt and action targets
        model_transforms = ModelTransformFactory()(model_config)

        # We return all data transforms for training and inference.
        return dataclasses.replace(
            self.create_base_config(assets_dirs, model_config),
            repack_transforms=repack_transform,
            data_transforms=data_transforms,
            model_transforms=model_transforms,
        )

