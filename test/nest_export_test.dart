import 'package:flutter_test/flutter_test.dart';

import 'package:equate/viewmodel/historical_data_viewmodel.dart';
import 'package:equate/viewmodel/nest_gold_viewmodel.dart';
import 'package:equate/viewmodel/nest_hangseng_viewmodel.dart';

void main() {
  test('NEST Gold exports a PDF after calculation', () async {
    final historicalDataViewModel = HistoricalDataViewModel();
    final viewModel = NestGoldViewModel(
      historicalDataViewModel: historicalDataViewModel,
    );
    addTearDown(historicalDataViewModel.dispose);
    addTearDown(viewModel.dispose);

    await Future<void>.delayed(Duration.zero);
    viewModel.setOpen('2400');
    viewModel.setClose('2410');

    expect(viewModel.calculateNest(), isTrue);

    final bytes = await viewModel.buildPdf();
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('NEST Hangseng exports a PDF after calculation', () async {
    final historicalDataViewModel = HistoricalDataViewModel();
    final viewModel = NestHangsengViewModel(
      historicalDataViewModel: historicalDataViewModel,
    );
    addTearDown(historicalDataViewModel.dispose);
    addTearDown(viewModel.dispose);

    await Future<void>.delayed(Duration.zero);
    viewModel.setOpen('24000');
    viewModel.setClose('24100');

    expect(viewModel.calculateNest(), isTrue);

    final bytes = await viewModel.buildPdf();
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
