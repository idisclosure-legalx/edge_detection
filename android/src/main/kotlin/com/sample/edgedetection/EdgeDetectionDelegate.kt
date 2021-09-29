package com.sample.edgedetection

import android.app.Activity
import android.content.Intent
import com.sample.edgedetection.scan.ScanActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class EdgeDetectionDelegate(activity: Activity) : PluginRegistry.ActivityResultListener {

    private var activity: Activity = activity
    private var result: MethodChannel.Result? = null
    private var methodCall: MethodCall? = null


    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {

        if (requestCode == SCAN_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                if (null != data && null != data.extras) {
                    val croppedImagePath = data.extras!!.getString(CROPPED_IMAGE_PATH)
                    val originalImagePath = data.extras!!.getString(ORIGINAL_IMAGE_PATH)
                    val quadTL = data.extras!!.getDoubleArray(QUADRILATERAL_TOP_LEFT)
                    val quadTR = data.extras!!.getDoubleArray(QUADRILATERAL_TOP_RIGHT)
                    val quadBR = data.extras!!.getDoubleArray(QUADRILATERAL_BOTTOM_RIGHT)
                    val quadBL = data.extras!!.getDoubleArray(QUADRILATERAL_BOTTOM_LEFT)
                    finishWithSuccess(mapOf(
                            CROPPED_IMAGE_PATH to croppedImagePath,
                            ORIGINAL_IMAGE_PATH to originalImagePath,
                            QUADRILATERAL_TOP_LEFT to quadTL,
                            QUADRILATERAL_TOP_RIGHT to quadTR,
                            QUADRILATERAL_BOTTOM_RIGHT to quadBR,
                            QUADRILATERAL_BOTTOM_LEFT to quadBL
                    ))
                }
            } else if (resultCode == Activity.RESULT_CANCELED) {
                    finishWithSuccess(null)
            }
            return true;
        }

        return false;
    }

    fun OpenCameraActivity(call: MethodCall, result: MethodChannel.Result) {

        if (!setPendingMethodCallAndResult(call, result)) {
            finishWithAlreadyActiveError()
            return
        }

        var intent = Intent(Intent(activity.applicationContext, ScanActivity::class.java))
        activity.startActivityForResult(intent,SCAN_REQUEST_CODE)
    }

    private fun setPendingMethodCallAndResult(methodCall: MethodCall, result: MethodChannel.Result): Boolean {
        if (this.result != null) {
            return false
        }

        this.methodCall = methodCall
        this.result = result
        return true
    }

    private fun finishWithAlreadyActiveError() {
        finishWithError("already_active", "Edge detection is already active")
    }

    private fun finishWithError(errorCode: String, errorMessage: String) {
        result?.error(errorCode, errorMessage, null)
        clearMethodCallAndResult()
    }

    private fun finishWithSuccess(data: Map<String, Any>?) {
        result?.success(data)
        clearMethodCallAndResult()
    }

    private fun clearMethodCallAndResult() {
        methodCall = null
        result = null
    }

}