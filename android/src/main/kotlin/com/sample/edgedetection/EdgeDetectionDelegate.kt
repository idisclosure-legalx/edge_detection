package com.sample.edgedetection

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Intent
import android.media.ExifInterface
import android.net.Uri
import android.util.Log
import com.sample.edgedetection.SourceManager.Companion.pic
import com.sample.edgedetection.crop.CropActivity
import com.sample.edgedetection.processor.Corners
import com.sample.edgedetection.processor.processPicture
import com.sample.edgedetection.scan.ScanActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import org.opencv.core.*
import org.opencv.imgcodecs.Imgcodecs
import org.opencv.imgproc.Imgproc
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.IOException
import java.io.InputStream

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

    fun openCameraActivity(call: MethodCall, result: MethodChannel.Result) {
        if (!setPendingMethodCallAndResult(call, result)) {
            finishWithAlreadyActiveError()
            return
        }

        var intent = Intent(Intent(activity.applicationContext, ScanActivity::class.java))
        activity.startActivityForResult(intent,SCAN_REQUEST_CODE)
    }

    @SuppressLint("NewApi")
    fun openCroppingActivity(call: MethodCall, result: MethodChannel.Result) {
        if (!setPendingMethodCallAndResult(call, result)) {
            finishWithAlreadyActiveError()
            return
        }

        val args = call.arguments as HashMap<String, Any>
        val originalImagePath = args["original_image_path"] as String
        val quadTopLeft = args["quadrilateral_top_left"] as ArrayList<Double>
        val quadTopRight = args["quadrilateral_top_right"] as ArrayList<Double>
        val quadBottomRight = args["quadrilateral_bottom_right"] as ArrayList<Double>
        val quadBottomLeft = args["quadrilateral_bottom_left"] as ArrayList<Double>

        val imageUri = Uri.fromFile(File(originalImagePath))
        val iStream: InputStream = this.activity.contentResolver.openInputStream(imageUri)

        val exif = ExifInterface(iStream);

        val imageWidth = exif.getAttributeInt(ExifInterface.TAG_IMAGE_WIDTH, 0).toDouble()
        val imageHeight = exif.getAttributeInt(ExifInterface.TAG_IMAGE_LENGTH, 0).toDouble()

        val inputData: ByteArray? = getBytes(this.activity.contentResolver.openInputStream(imageUri))
        val mat = Mat(Size(imageWidth, imageHeight), CvType.CV_8U)
        mat.put(0, 0, inputData)
        val pic = Imgcodecs.imdecode(mat, Imgcodecs.CV_LOAD_IMAGE_UNCHANGED)
        mat.release()
        Imgproc.cvtColor(pic, pic, Imgproc.COLOR_RGB2BGRA)

        val corners = Corners(
            corners = listOf(
                Point(quadTopLeft[0], quadTopLeft[1]),
                Point(quadTopRight[0], quadTopRight[1]),
                Point(quadBottomRight[0], quadBottomRight[1]),
                Point(quadBottomLeft[0], quadBottomLeft[1])
            ),
            size = mat.size()
        )

        val intent = Intent(Intent(activity.applicationContext, CropActivity::class.java))
        SourceManager.pic = pic
        SourceManager.corners = corners
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


    @Throws(IOException::class)
    fun getBytes(inputStream: InputStream): ByteArray? {
        val byteBuffer = ByteArrayOutputStream()
        val bufferSize = 1024
        val buffer = ByteArray(bufferSize)
        var len = 0
        while (inputStream.read(buffer).also { len = it } != -1) {
            byteBuffer.write(buffer, 0, len)
        }
        return byteBuffer.toByteArray()
    }
}