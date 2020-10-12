$('.t-Login-region').append('<div id="camera" style="width: 320px;height: 240px;display: none;" ></div>');

function showError(message){
        apex.message.showErrors([
            {
                type:       "error",
                location:   "page",
                message:    message,
                unsafe:     false
            }
        ]);
}

Webcam.set({
    width: 320,
    height: 240,
    image_format: 'jpeg',
    jpeg_quality: 90
});
Webcam.attach('#camera');

function takePicture() {
    Webcam.snap(function(data_uri) {
        base_image = new Image();
        base_image.src = data_uri;
        base_image.onload = function() {
            fetch(data_uri)
                .then(res => res.blob())
                .then(blobData => {
                    $.post({
                            url: "https://northeurope.api.cognitive.microsoft.com/face/v1.0/detect?returnFaceId=true&returnFaceLandmarks=false&recognitionModel=recognition_01&returnRecognitionModel=false&detectionModel=detection_01",
                            contentType: "application/octet-stream",
                            headers: {
                                'Ocp-Apim-Subscription-Key': '<add the API KEY here>'
                            },
                            processData: false,
                            data: blobData
                        })
                        .done(function(data) {
                            if (data.length) { 
                                apex.item('P9999_FACE_ID').setValue(data[0].faceId);                                 
                            }else{
                                showError('Face not detected, try again');
                            }
                                
                        })
                        .fail(function(err) {
                            console.log(JSON.stringify(err));
                        })
                });
        }
    });
};
