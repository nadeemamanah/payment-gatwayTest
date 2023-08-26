package com.isg.isgpayui_plugin;

import android.app.Activity;
import android.content.Intent;

import androidx.annotation.NonNull;

import com.isgpaymediatorbank.ISGPayController;
import com.isgpaymediatorbank.listener.ISGPayControllerInterface;
import com.isgpaymediatorbank.listener.ISGPayTransactionInterface;
import com.isgpaymediatorbank.listener.PaymentResponseListener;
import com.isgpaymediatorbank.request.ISGPayRequest;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;



/** IsgpayuiPlugin */
public class IsgpayuiPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener, PaymentResponseListener {

  private Activity activityContext;
  private static final String METHOD_CALL_LAUNCH_SDK = "initiateISGPayUI";
  private static final String KEY_INPUT_JSON = "inputParams";
  private final static int REQ_CODE_LAUNCH_SDK = 101;
  private Result result;

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    this.result = result;
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    } else if (call.method.equals(METHOD_CALL_LAUNCH_SDK)) {
      launchSDK(call);
    } else {
      result.notImplemented();
    }
  }

  private void launchSDK(MethodCall methodCall) {
    if (methodCall.hasArgument(KEY_INPUT_JSON)) {
      Map<String, String> inputParams = methodCall.argument(KEY_INPUT_JSON);
      try {
        assert inputParams != null;
        JSONObject params = new JSONObject(inputParams);
        processPayment(params);
      } catch (JSONException e) {
        resultFailedTxn(ErrorCode.INVALID_INPUT, ErrorMessage.INVALID_INPUT);
      }
    } else {
      resultFailedTxn(ErrorCode.INVALID_INPUT, ErrorMessage.INVALID_INPUT);
    }
  }

  private void processPayment(JSONObject inputParams) throws JSONException {


    // Initialize isg pay request
    ISGPayRequest isgPay = new ISGPayRequest();

    // Set data to request
    isgPay.setBaseUrl("https://pgcloudpoc.insolutionsglobal.com:8464/ISGPay-Genius/request.action"); // Optional - use default URL
    isgPay.setVersion(inputParams.getString("version")); // fix pass 1
    isgPay.setTxnRefNo(inputParams.getString("txnRefNo"));//this should be unique code every request
    isgPay.setAmount(inputParams.getString("amount"));//amount should be in paisa
    isgPay.setPassCode(inputParams.getString("passCode"));//merchant passcode provide by PG
    isgPay.setBankId(inputParams.getString("bankId")); //provide by PG
    isgPay.setTerminalId(inputParams.getString("terminalId"));//provide by PG
    isgPay.setMerchantId(inputParams.getString("merchantId"));//provide by PG
    isgPay.setMCC(inputParams.getString("mcc"));//provide by PG
    isgPay.setCurrency(inputParams.getString("currency"));//fix currency code
    isgPay.setPaymentType(inputParams.getString("paymentType"));//fix "Pay" in payment type
    isgPay.setOrderInfo(inputParams.getString("orderInfo"));//This is your order id for which collecting payment
    isgPay.setHashKey(inputParams.getString("hashKey"));//provide by PG
    isgPay.setAesKey(inputParams.getString("aesKey"));//provide by PG
    isgPay.setEnvironment(inputParams.getString("env").equalsIgnoreCase("PROD") ? ISGPayRequest.Environment.PRODUCTION : ISGPayRequest.Environment.UAT);

    // Make payment
    ISGPayControllerInterface isgPayControllerInterface = ISGPayController.getInstance();
    ISGPayTransactionInterface isgPayTransactionInterface = isgPayControllerInterface
            .withContext(activityContext)
            .setPaymentResponseListener(this)
            .initialise();
    isgPayTransactionInterface.makePayment(isgPay);



  }

  @Override
  public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
    return false;
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    MethodChannel channel = new MethodChannel(binding.getBinaryMessenger(), "isgpayui_plugin");
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {

  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    this.activityContext = binding.getActivity();
    binding.addActivityResultListener(this);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {

  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

  }

  @Override
  public void onDetachedFromActivity() {

  }

  @Override
  public void onSuccess(String result) {
    resultSuccessTxn(result);
  }

  @Override
  public void onFail(String errorCode, String errorMessage) {
    resultFailedTxn(errorCode, errorMessage);
  }

  public interface ErrorMessage {
    String USER_PRESSED_BACK_BUTTON = "User pressed back button.";
    String INVALID_INPUT = "Invalid input parameters.";
  }

  public interface ErrorCode {
    String USER_PRESSED_BACK_BUTTON = "101";
    String INVALID_INPUT = "102";
  }

  private void resultFailedTxn(String errorCode, String errorDESC) {
    result.error(errorCode, errorDESC, errorDESC);
  }

  private void resultSuccessTxn(String msg) {
    result.success(msg);
  }
}
