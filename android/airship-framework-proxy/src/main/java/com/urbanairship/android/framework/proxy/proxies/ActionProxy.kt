package com.urbanairship.android.framework.proxy.proxies

public class ActionProxy {

//
//    /**
//     * Runs an action.
//     *
//     * @param name    The action's name.
//     * @param value   The action's value.
//     * @param promise A JS promise to deliver the action result.
//     */
//    fun runAction(name: String, value: Dynamic?, promise: Promise) {
//        if (!Utils.ensureAirshipReady(promise)) {
//            return
//        }
//        ActionRunRequest.createRequest(name)
//            .setValue(Utils.convertDynamic(value))
//            .run(ActionCompletionCallback { actionArguments, actionResult ->
//                when (actionResult.status) {
//                    ActionResult.STATUS_COMPLETED -> {
//                        promise.resolve(Utils.convertJsonValue(actionResult.value.toJsonValue()))
//                        return@ActionCompletionCallback
//                    }
//                    ActionResult.STATUS_REJECTED_ARGUMENTS -> {
//                        promise.reject("STATUS_REJECTED_ARGUMENTS", "Action rejected arguments.")
//                        return@ActionCompletionCallback
//                    }
//                    ActionResult.STATUS_ACTION_NOT_FOUND -> {
//                        promise.reject("STATUS_ACTION_NOT_FOUND", "Action " + name + "not found.")
//                        return@ActionCompletionCallback
//                    }
//                    ActionResult.STATUS_EXECUTION_ERROR -> {
//                        promise.reject("STATUS_EXECUTION_ERROR", actionResult.exception)
//                        return@ActionCompletionCallback
//                    }
//                    else -> {
//                        promise.reject("STATUS_EXECUTION_ERROR", actionResult.exception)
//                        return@ActionCompletionCallback
//                    }
//                }
//            })
//    }
//

}