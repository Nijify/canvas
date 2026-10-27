// Path: packages/canvas_background_removal_isnet/lib/src/isnet_model_contract.dart

import 'package:canvas_background_removal_isnet/src/isnet_failure.dart';

final class IsnetModelIdentity {
  const IsnetModelIdentity({required this.sizeBytes, required this.sha256});

  final int sizeBytes;
  final String sha256;
}

final class IsnetTensorDescriptor {
  const IsnetTensorDescriptor({
    required this.name,
    required this.dtype,
    required this.shape,
  });

  final String name;
  final String dtype;
  final List<int> shape;
}

final class IsnetExpectedTensor {
  const IsnetExpectedTensor({
    required this.name,
    required this.dtype,
    required this.shape,
  });

  final String name;
  final String dtype;
  final List<int> shape;
}

abstract final class IsnetModelContract {
  static const modelId = 'isnet-general-use';

  static const candidateIdentity = IsnetModelIdentity(
    sizeBytes: 88135432,
    sha256: '325ecf784635a998bd55e3fa622f4bc3a42834a8a4a1e08ed58f147eebdfda0a',
  );

  static const inputOrdinal = 0;
  static const input = IsnetExpectedTensor(
    name: 'inputs_0',
    dtype: 'float32',
    shape: <int>[1, 1024, 1024, 3],
  );

  static const primaryOutputOrdinal = 0;
  static const outputs = <IsnetExpectedTensor>[
    IsnetExpectedTensor(
      name: 'Identity',
      dtype: 'float32',
      shape: <int>[1, 1024, 1024, 1],
    ),
    IsnetExpectedTensor(
      name: 'Identity_1',
      dtype: 'float32',
      shape: <int>[1, 1024, 1024, 1],
    ),
    IsnetExpectedTensor(
      name: 'Identity_2',
      dtype: 'float32',
      shape: <int>[1, 1024, 1024, 1],
    ),
    IsnetExpectedTensor(
      name: 'Identity_3',
      dtype: 'float32',
      shape: <int>[1, 1024, 1024, 1],
    ),
    IsnetExpectedTensor(
      name: 'Identity_4',
      dtype: 'float32',
      shape: <int>[1, 1024, 1024, 1],
    ),
    IsnetExpectedTensor(
      name: 'Identity_5',
      dtype: 'float32',
      shape: <int>[1, 1024, 1024, 1],
    ),
    IsnetExpectedTensor(
      name: 'Identity_6',
      dtype: 'float32',
      shape: <int>[1, 512, 512, 64],
    ),
    IsnetExpectedTensor(
      name: 'Identity_7',
      dtype: 'float32',
      shape: <int>[1, 256, 256, 64],
    ),
    IsnetExpectedTensor(
      name: 'Identity_8',
      dtype: 'float32',
      shape: <int>[1, 128, 128, 128],
    ),
    IsnetExpectedTensor(
      name: 'Identity_9',
      dtype: 'float32',
      shape: <int>[1, 64, 64, 256],
    ),
    IsnetExpectedTensor(
      name: 'Identity_10',
      dtype: 'float32',
      shape: <int>[1, 32, 32, 512],
    ),
    IsnetExpectedTensor(
      name: 'Identity_11',
      dtype: 'float32',
      shape: <int>[1, 16, 16, 512],
    ),
  ];

  static const inputElementCount = 1024 * 1024 * 3;
  static const primaryOutputElementCount = 1024 * 1024;

  static void validate({
    required List<IsnetTensorDescriptor> inputs,
    required List<IsnetTensorDescriptor> outputs,
  }) {
    if (inputs.length != 1) {
      throw IsnetException(
        IsnetFailureKind.modelContractMismatch,
        cause: 'Expected 1 input tensor, found ${inputs.length}.',
      );
    }

    if (outputs.length != IsnetModelContract.outputs.length) {
      throw IsnetException(
        IsnetFailureKind.modelContractMismatch,
        cause:
            'Expected ${IsnetModelContract.outputs.length} output tensors, '
            'found ${outputs.length}.',
      );
    }

    _validateTensor(
      role: 'input',
      ordinal: inputOrdinal,
      actual: inputs[inputOrdinal],
      expected: input,
    );

    for (
      var ordinal = 0;
      ordinal < IsnetModelContract.outputs.length;
      ordinal++
    ) {
      _validateTensor(
        role: 'output',
        ordinal: ordinal,
        actual: outputs[ordinal],
        expected: IsnetModelContract.outputs[ordinal],
      );
    }
  }

  static void _validateTensor({
    required String role,
    required int ordinal,
    required IsnetTensorDescriptor actual,
    required IsnetExpectedTensor expected,
  }) {
    if (actual.name != expected.name) {
      throw IsnetException(
        IsnetFailureKind.modelContractMismatch,
        cause:
            '$role ordinal $ordinal name mismatch: '
            'expected "${expected.name}", found "${actual.name}".',
      );
    }

    if (actual.dtype != expected.dtype) {
      throw IsnetException(
        IsnetFailureKind.modelContractMismatch,
        cause:
            '$role ordinal $ordinal dtype mismatch: '
            'expected "${expected.dtype}", found "${actual.dtype}".',
      );
    }

    if (!_sameShape(actual.shape, expected.shape)) {
      throw IsnetException(
        IsnetFailureKind.modelContractMismatch,
        cause:
            '$role ordinal $ordinal shape mismatch: '
            'expected ${expected.shape}, found ${actual.shape}.',
      );
    }
  }

  static bool _sameShape(List<int> left, List<int> right) {
    if (left.length != right.length) {
      return false;
    }

    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }

    return true;
  }
}
