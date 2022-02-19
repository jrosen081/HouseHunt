import * as functions from "firebase-functions";
import * as admin from 'firebase-admin';
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

function sendNotification(title: string, message: string, tokens: string[]) {
    const notification: admin.messaging.MulticastMessage = {
        notification: {
            title: title,
            body: message
        },
        tokens: tokens
    }
    return messaging.sendMulticast(notification)
}

const getTokensForUser = async (userId: string) => {
    const user = await db.doc(`users/${userId}`).get()
    const userData = user.data()
    if (!userData) {
        console.log(`Found user ${userId} with no firebase tokens`);
        throw new Error("No user with id " + userId)
    }
    const tokens: string[] = userData.tokens;
    return tokens
}

export const sendApartmentAddedNotification = functions.firestore
    .document("apartments/{apartmentId}/apartments/{postID}")
    .onCreate(async (change, context) => {
        const dataRef = await db.doc(`apartments/{apartmentId}`).get()
        const data = dataRef.data()
        if (!data) {
            return
        }
        const users: string[] = data.users;
        const allTokens: string[] = []
        for (const userId of users) {
            if (userId === change.data().author) {
                continue;
            }
            try {
                const tokens: string[] = await getTokensForUser(userId);
                allTokens.push(...tokens)
            } catch (err) {
                console.error(err)
                continue
            }
        }
        return sendNotification("New Home", "A Home was added to your search!", allTokens)
    })

function diff(old: string[], newOnes: string[]): {removed: string[], added: string[]} {
    const removed: string[] = []
    const added: string[] = []
    const oldObject: any = {}
    const newObject: any = {}
    for (const oldVal of old) {
        oldObject[oldVal] = true
    }

    for (const newVal of newOnes) {
        newObject[newVal] = true
        if (!oldObject[newVal]) {
            added.push(newVal)
        }
    }

    for (const oldVal of old) {
        if (!newObject[oldVal]) {
            removed.push(oldVal)
        }
    }

    return {
        removed,
        added
    }
}

export const sendUserAddedRemovedNotification = functions.firestore
    .document("apartments/{apartmentId}")
    .onUpdate(async (change, context) => {
        const previousRequests: string[] = change.before.data().requests;
        const newRequests: string[] = change.after.data().requests;
        const newUsers: string[] = change.after.data().users;
        const { removed, added } = diff(previousRequests, newRequests);
        for (const removal of removed) {
            if (removal === context.auth?.uid) {
                continue;
            }
            try {
                const tokens = await getTokensForUser(removal)
                if (newUsers.includes(removal)) {
                    await sendNotification("Success!", "Your Home Search Request was accepted!", tokens)
                } else {
                    await sendNotification("Try Again!", "Oh no! You were not accepted to the Home Search.", tokens)
                }
            } catch (error) {
                console.error(error)
            }
        }
        if (added.length > 0) {
            const allTokens: string[] = []
            for (const user of newUsers) {
                if (user === context.auth?.uid) {
                    continue;
                }
                try {
                    allTokens.push(...await getTokensForUser(user))
                } catch (error) {
                    console.error(error)
                }
            }
            await sendNotification("New Request", "Someone requested to join your Home Search!", allTokens)
        }
    })
