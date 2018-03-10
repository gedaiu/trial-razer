module trialrazer.plugin;

import trial.interfaces;
import trial.runner;
import razer.chroma;

import std.conv;
import std.range;
import std.algorithm;
import std.math;
import std.array;


static this() {
  foreach(device; chromaDevices) {
    LifeCycleListeners.instance.add(new RazerReporter(device));
  }
}

/// The "Razer" reporter implements a simple progress-bar that is
/// displayed using the RGB Leds from your keyboard
class RazerReporter : ITestCaseLifecycleListener, ILifecycleListener
{
  private
  {
    double total;
    double testCount;
    double currentTest;
    double percentage;

    RazerChromaDevice device;
    Color success;
    Color blank;
    Color fail;
  }

  this(RazerChromaDevice device)
  {
    this.device = device;
    this.total = device.width * device.height;

    this.success = Color(0, 200, 0);
    this.blank = Color(0, 0, 200);
    this.fail = Color(200, 0, 0);
  }

  void begin(ulong testCount)
  {
    this.testCount = testCount;
    percentage = 0;
    currentTest = 0;
  }

  void update()
  {

  }

  void end(SuiteResult[])
  {

  }

  void begin(string suite, ref TestResult test)
  {
  }

  void end(string suite, ref TestResult test)
  {
    currentTest++;
    percentage = currentTest / testCount;
    draw;
  }

  private void draw()
  {
    auto colors = iota(0, percentage * total)
      .map!(a => success)
      .array;

    auto currentIndex = colors.length / total;
    auto nextIndex = (colors.length + 1) / total;
    auto stepSize = nextIndex - currentIndex;
    auto stepPercentage = 1 - (currentIndex - percentage) / stepSize;

    if(colors.length != total) {
      colors ~= transition(stepPercentage, blank, success);
      colors ~= iota(colors.length, total).map!(a => blank).array;
    }

    if(colors.length < total - 1) {
      colors ~= iota(colors.length, total).map!(a => blank).array;
    }

    auto rows = colors.evenChunks(device.height)
        .enumerate
        .map!(a => (a.index % 2) ? a.value.array.reverse.array : a.value.array)
        .enumerate
        .array;

    foreach(row; rows) {
      device.setKeyRow(row.index.to!ubyte, row.value);
    }

    device.flush;
  }
}