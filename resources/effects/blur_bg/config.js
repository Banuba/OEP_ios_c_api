function Effect() {
    var self = this;

    this.init = function() {
        Api.meshfxMsg("spawn", 0, 0, "tri.bsm2");

        setBlurRaduis(3);

        Api.showRecordButton();
    };

    this.restart = function() {
        Api.meshfxReset();
        self.init();
    };

    this.faceActions = [];
    this.noFaceActions = [];

    this.videoRecordStartActions = [];
    this.videoRecordFinishActions = [];
    this.videoRecordDiscardActions = [this.restart];
}

function setBlurRaduis(intRadius){
    if (intRadius > 8 || intRadius < 3) {
        Api.print("setBlurRaduis - please set radius in range [3,8] as integer value.");
    } else {
        Api.meshfxMsg("blur", 0, intRadius);

        Api.print("setBlurRaduis - blur radius " + intRadius + "is set");
    }
    
}

configure(new Effect());