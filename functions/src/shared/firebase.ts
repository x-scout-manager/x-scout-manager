import {getApps, initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {setGlobalOptions} from "firebase-functions/v2";

setGlobalOptions({
  region: "asia-northeast1",
  maxInstances: 10,
});

if (getApps().length === 0) {
  initializeApp();
}

export const db = getFirestore();
