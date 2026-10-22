// Path: private_packages/bg_remover_isnet/test/isnet_model_contract_test.dart

import 'package:canvas_background_removal_isnet/bg_remover_isnet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<IsnetTensorDescriptor> validInputs() {
    final expected = IsnetModelContract.input;
    return <IsnetTensorDescriptor>[
      IsnetTensorDescriptor(
        name: expected.name,
        dtype: expected.dtype,
        shape: expected.shape,
      ),
    ];
  }

  List<IsnetTensorDescriptor> validOutputs() {
    return <IsnetTensorDescriptor>[
      for (final expected in IsnetModelContract.outputs)
        IsnetTensorDescriptor(
          name: expected.name,
          dtype: expected.dtype,
          shape: expected.shape,
        ),
    ];
  }

  test('frozen candidate identity matches evidence', () {
    expect(IsnetModelContract.candidateIdentity.sizeBytes, 88135432);
    expect(
      IsnetModelContract.candidateIdentity.sha256,
      '325ecf784635a998bd55e3fa622f4bc3a42834a8a4a1e08ed58f147eebdfda0a',
    );
    expect(IsnetModelContract.primaryOutputOrdinal, 0);
    expect(IsnetModelContract.outputs, hasLength(12));
  });

  test('accepts the frozen tensor contract', () {
    expect(
      () => IsnetModelContract.validate(
        inputs: validInputs(),
        outputs: validOutputs(),
      ),
      returnsNormally,
    );
  });

  test('rejects wrong output count', () {
    final outputs = validOutputs()..removeLast();

    expect(
      () =>
          IsnetModelContract.validate(inputs: validInputs(), outputs: outputs),
      throwsA(
        isA<IsnetException>().having(
          (error) => error.kind,
          'kind',
          IsnetFailureKind.modelContractMismatch,
        ),
      ),
    );
  });

  test('rejects wrong primary output shape', () {
    final outputs = validOutputs();
    outputs[0] = const IsnetTensorDescriptor(
      name: 'Identity',
      dtype: 'float32',
      shape: <int>[1, 512, 512, 1],
    );

    expect(
      () =>
          IsnetModelContract.validate(inputs: validInputs(), outputs: outputs),
      throwsA(
        isA<IsnetException>().having(
          (error) => error.kind,
          'kind',
          IsnetFailureKind.modelContractMismatch,
        ),
      ),
    );
  });

  test('rejects wrong primary output name', () {
    final outputs = validOutputs();
    outputs[0] = const IsnetTensorDescriptor(
      name: 'WrongOutput',
      dtype: 'float32',
      shape: <int>[1, 1024, 1024, 1],
    );

    expect(
      () =>
          IsnetModelContract.validate(inputs: validInputs(), outputs: outputs),
      throwsA(
        isA<IsnetException>().having(
          (error) => error.kind,
          'kind',
          IsnetFailureKind.modelContractMismatch,
        ),
      ),
    );
  });

  test('rejects wrong input dtype', () {
    const inputs = <IsnetTensorDescriptor>[
      IsnetTensorDescriptor(
        name: 'inputs_0',
        dtype: 'float16',
        shape: <int>[1, 1024, 1024, 3],
      ),
    ];

    expect(
      () =>
          IsnetModelContract.validate(inputs: inputs, outputs: validOutputs()),
      throwsA(
        isA<IsnetException>().having(
          (error) => error.kind,
          'kind',
          IsnetFailureKind.modelContractMismatch,
        ),
      ),
    );
  });
}
