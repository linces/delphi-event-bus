unit EventBusTestU;

interface

uses
  DUnitX.TestFramework, BaseTestU;

type

  [TestFixture]
  TEventBusTest = class(TBaseTest)
  public
    [Test]
    procedure TestRegisterUnregister;
    [Test]
    procedure TestIsRegisteredTrueAfterRegister;
    [Test]
    procedure TestIsRegisteredFalseAfterUnregister;
    [Test]
    procedure TestSimplePost;
    [Test]
    procedure TestAsyncPost;
    [Test]
    procedure TestPostOnMainThread;
  end;

implementation

uses EventBus, BOs, System.SyncObjs, System.SysUtils;

procedure TEventBusTest.TestSimplePost;
var
  LEvent: TEventBusEvent;
  LMsg: string;
begin
  TEventBus.GetDefault.RegisterSubscriber(Subscriber);
  LEvent := TEventBusEvent.Create;
  LMsg := 'TestSimplePost';
  LEvent.Msg := LMsg;
  TEventBus.GetDefault.Post(LEvent);
  Assert.AreEqual(LMsg, Subscriber.LastEvent.Msg);
end;

procedure TEventBusTest.TestRegisterUnregister;
var
  LRaisedException: Boolean;
begin
  LRaisedException := false;
  TEventBus.GetDefault.RegisterSubscriber(Subscriber);
  try
    TEventBus.GetDefault.Unregister(Subscriber);
  except
    on E: Exception do
      LRaisedException := true;
  end;
  Assert.IsFalse(LRaisedException);
end;

procedure TEventBusTest.TestIsRegisteredFalseAfterUnregister;
begin
  TEventBus.GetDefault.RegisterSubscriber(Subscriber);
  Assert.IsTrue(TEventBus.GetDefault.IsRegistered(Subscriber));
end;

procedure TEventBusTest.TestIsRegisteredTrueAfterRegister;
begin
  TEventBus.GetDefault.RegisterSubscriber(Subscriber);
  TEventBus.GetDefault.Unregister(Subscriber);
  Assert.IsFalse(TEventBus.GetDefault.IsRegistered(Subscriber));
end;

procedure TEventBusTest.TestPostOnMainThread;
var
  LEvent: TMainEvent;
  LMsg: string;
begin
  TEventBus.GetDefault.RegisterSubscriber(Subscriber);
  LEvent := TMainEvent.Create;
  LMsg := 'TestPostOnMainThread';
  LEvent.Msg := LMsg;
  TEventBus.GetDefault.Post(LEvent);
  Assert.AreEqual(LMsg, Subscriber.LastEvent.Msg);
  Assert.AreEqual(MainThreadID, Subscriber.LastEventThreadID);
end;

procedure TEventBusTest.TestAsyncPost;
var
  LEvent: TAsyncEvent;
  LMsg: string;
  LEvt: TEvent;
begin
  TEventBus.GetDefault.RegisterSubscriber(Subscriber);
  LEvent := TAsyncEvent.Create;
  LMsg := 'TestAsyncPost';
  LEvent.Msg := LMsg;
  LEvt := TEvent.Create;
  try
    LEvent.Event := LEvt;
    TEventBus.GetDefault.Post(LEvent);
    // attend for max 5 seconds
    Assert.IsTrue(TWaitResult.wrSignaled = LEvt.WaitFor(5000),
      'Timeout request');
    Assert.AreEqual(LMsg, Subscriber.LastEvent.Msg);
    Assert.AreNotEqual(MainThreadID, Subscriber.LastEventThreadID);
  finally
    LEvt.Free;
  end;
end;

initialization

TDUnitX.RegisterTestFixture(TEventBusTest);

end.
