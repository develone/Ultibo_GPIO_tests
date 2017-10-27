program GPIOPerformanceTest;

{$mode objfpc}{$H+}

uses
  GlobalConst,
  GlobalTypes,
  GlobalConfig,
  Platform,
  Threads,
  Console,
  Framebuffer,
  BCM2837,
  BCM2710,
  SysUtils,
  GPIO;


const
  MAX_JITTER = 100000; // us
  RUN_TIME = 100000000; // us

var
 WindowHandle:TWindowHandle;
 startTime, processingTime, prevProcessingTime, jitter, counter : int64;
 jitterHistogram : array[ 0..MAX_JITTER ] of integer;
 i : integer;

begin
  for i := 0 to MAX_JITTER do
  begin
    jitterHistogram[ i ] := 0;
  end;
  counter := 0;
  WindowHandle:=ConsoleWindowCreate(ConsoleDeviceGetDefault,CONSOLE_POSITION_FULL,True);

  ConsoleWindowWriteLn(WindowHandle,'GPIO performance test');
  ConsoleWindowWriteLn(WindowHandle,'Clock cycles per millisecond: ' + inttostr(  CLOCK_CYCLES_PER_MILLISECOND  ) );

  GPIOFunctionSelect(GPIO_PIN_16,GPIO_FUNCTION_OUT);
  GPIOOutputSet(GPIO_PIN_16,GPIO_LEVEL_LOW);

  DisableIRQ;

  startTime := ClockGetTotal();
  prevProcessingTime := ClockGetTotal();
  while ( prevProcessingTime - startTime < RUN_TIME ) do
  begin
    PLongWord(BCM2837_GPIO_REGS_BASE + BCM2837_GPSET0)^:=$00010000;
    processingTime := ClockGetTotal();
    jitter := processingTime - prevProcessingTime;
    if ( jitter > MAX_JITTER ) then jitter := MAX_JITTER;
    PLongWord(BCM2837_GPIO_REGS_BASE + BCM2837_GPCLR0)^:=$00010000;
    inc( jitterHistogram[ jitter ] );
    prevProcessingTime := processingTime;
    inc( counter );
  end;

  EnableIRQ;

  ConsoleWindowWriteLn(WindowHandle, 'Average toggle rate: ' + floattostr( counter / RUN_TIME ) + ' MHz' );

  for i := 0 to MAX_JITTER do
  begin
    if jitterHistogram[ i ] > 0 then
    begin
      ConsoleWindowWriteLn(WindowHandle,'Jitter count for ' + inttostr( i ) + ' us: ' +  inttostr( jitterHistogram[ i ] ) );
    end;
  end;

  ThreadHalt(0);
end.

