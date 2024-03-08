package de.fraunhofer.iis.shore.wrapper;

public interface IMessageCallback {

	/**************************************************************************
	 * Override this interface in order to receive callback message to 
	 * @param message
	 *************************************************************************/
	public void MessageCallback(String message); 
}
