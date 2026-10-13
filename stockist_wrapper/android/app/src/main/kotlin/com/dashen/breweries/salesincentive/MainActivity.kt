package com.dashen.breweries.salesincentive

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import com.google.android.gms.auth.api.phone.SmsRetriever
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.common.api.Status
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.regex.Pattern

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.dashen.breweries/otp"
    private val SMS_CONSENT_REQUEST = 2
    private var otpResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "startSmsConsent") {
                otpResult = result
                startSmsUserConsent()
            } else {
                result.notImplemented()
            }
        }
    }

    private fun startSmsUserConsent() {
        val client = SmsRetriever.getClient(this)
        client.startSmsUserConsent(null) // null sender means it listens to any sender
        
        val intentFilter = IntentFilter(SmsRetriever.SMS_RETRIEVED_ACTION)
        // Register receiver for SMS Consent
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(smsVerificationReceiver, intentFilter, SmsRetriever.SEND_PERMISSION, null, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(smsVerificationReceiver, intentFilter, SmsRetriever.SEND_PERMISSION, null)
        }
    }

    private val smsVerificationReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (SmsRetriever.SMS_RETRIEVED_ACTION == intent.action) {
                val extras = intent.extras
                val smsRetrieverStatus = extras?.get(SmsRetriever.EXTRA_STATUS) as? Status

                when (smsRetrieverStatus?.statusCode) {
                    CommonStatusCodes.SUCCESS -> {
                        val consentIntent = extras.getParcelable<Intent>(SmsRetriever.EXTRA_CONSENT_INTENT)
                        try {
                            startActivityForResult(consentIntent, SMS_CONSENT_REQUEST)
                        } catch (e: ActivityNotFoundException) {
                            otpResult?.error("ACTIVITY_NOT_FOUND", "Could not start consent activity", null)
                        }
                    }
                    CommonStatusCodes.TIMEOUT -> {
                        otpResult?.error("TIMEOUT", "SMS retrieval timed out", null)
                    }
                }
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == SMS_CONSENT_REQUEST) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val message = data.getStringExtra(SmsRetriever.EXTRA_SMS_MESSAGE)
                val otp = extractOtp(message)
                if (otp != null) {
                    otpResult?.success(otp)
                } else {
                    otpResult?.error("NOT_FOUND", "No OTP found in message", null)
                }
            } else {
                otpResult?.error("CANCELLED", "User cancelled consent", null)
            }
        }
    }

    private fun extractOtp(message: String?): String? {
        if (message == null) return null
        val pattern = Pattern.compile("(\\d{4,6})")
        val matcher = pattern.matcher(message)
        if (matcher.find()) {
            return matcher.group(0)
        }
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(smsVerificationReceiver)
        } catch (e: IllegalArgumentException) {
            // Receiver not registered
        }
    }
}
